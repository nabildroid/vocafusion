import { cors } from "hono/cors";
import { CreateHono } from "..";
import { drizzle } from 'drizzle-orm/d1';
import { usersTable } from "../db/schema";
import { eq } from 'drizzle-orm';
import { analytics } from "../utils";
import Stripe from "stripe";
import GoogleProvider from "../repositories/googleProvider";
import GooglePlayProvider, { type IPlayOffer } from "../repositories/googlePlayProvider";


const PaymentAPI = CreateHono();
PaymentAPI.use('*', cors())



async function getPeriodicallyCachedPricing(c: any): Promise<IPlayOffer[]> {
    const packageName = "me.laknabil.voca";

    // request are generly very slow to the GooglePlayProvider, better cached for 5 minutes
    const cache = await caches.open("default")
    const cacheKey = new Request("https://payment.pricing." + packageName);
    const cached = await cache.match(cacheKey);

    if (cached) {
        console.log("From cache")
        const cachedData = await cached.json();
        return cachedData as any;
    }

    const google = new GoogleProvider(c.env);
    console.debug("got google");


    const play = new GooglePlayProvider(google, packageName);
    const offers = await play.getOffers();

    console.debug("got offers", offers);

    const response = Response.json(offers);
    response.headers.append("Cache-Control", "s-maxage=900");
    await cache.put(cacheKey, response);

    return offers;
}

PaymentAPI.get("/pricing", async (c) => {
    const offers = await getPeriodicallyCachedPricing(c);

    return c.json({ offers })
})

PaymentAPI.get("/:uid/:productId", async (c) => {
    const { uid, productId } = c.req.param();
    // const user = await drizzle(c.env.DB).select().from(usersTable).where(eq(usersTable.uid, uid)).get()

    // if (!user) {
    //     return c.json({ message: "user not found" }, { status: 404 })
    // }

    // if (user.claims?.premiumExpires) {
    //     const now = new Date().getTime();
    //     if (now < user.claims.premiumExpires) {
    //         return c.json({ status: "error", message: "User already has premium" });
    //     }
    // }
    const pricing = await getPeriodicallyCachedPricing(c);
    const target = pricing.find(e => e.basePlanId == productId || e.offerId == productId);


    const gate = new Stripe(c.env.STRIPE_KEY!);
    const link = await gate.checkout.sessions.create({
        line_items: [
            {
                price_data: {
                    currency: "usd",
                    product_data: {
                        name: "Premium Subscription",
                    },
                    unit_amount: (target?.usdPrice ?? 10) * 100,
                },
                quantity: 1,
            },
        ],
        mode: 'payment',
        success_url: "https://vocafusion.laknabil.me/success",
        cancel_url: "https://vocafusion.laknabil.me/error",
        metadata: {
            uid,
            productId: target?.basePlanId ?? productId,
            offerId: target?.offerId ?? productId,
            package: "me.laknabil.vocafusion"
        },
    })

    return c.redirect(link.url!);
});



PaymentAPI.post("/webhook/stripe", async (c) => {
    const body = await c.req.json();
    console.log(body);
    if (body.type != "checkout.session.completed" || body.data.object.metadata.package != "me.laknabil.vocafusion") {
        return c.json({ status: "error", message: "Invalid event type" });
    }


    const { uid } = body.data.metadata;
    const amount = body.data.amount;
    const invoiceId = body.data.invoice_id;

    const user = await drizzle(c.env.DB).select().from(usersTable).where(eq(usersTable.uid, uid)).get()


    try {
        await drizzle(c.env.DB).update(usersTable).set({
            claims: {
                ...(user!.claims as any),
                premiumExpires: new Date().getTime() + 30 * 24 * 60 * 60 * 1000
            }
        }).where(eq(usersTable.uid, uid)).run();
        await fetch("https://wirepusher.com/send?type=chargily&id=b7KJmpGkn&title=you Got Money&message=You got " + amount + " DZD from " + uid + " with invoice id " + invoiceId);

        await analytics({
            userId: uid,
            event: "Payment",
            properties: {
                amount,
                invoiceId,
                paymentMethod: body.data.payment_method,
                description: body.data.description
            }
        });
    } catch (e) {
        await fetch("https://wirepusher.com/send?type=chargily&id=b7KJmpGkn&title=Error&message=Error while updating user " + uid + " with invoice id " + invoiceId);
    }

    return c.json({ status: "success", message: "Payment received", uid, amount });
});



// accepting the google play purchase token
PaymentAPI.post("/purchase/google-play/verify/:uid", async (c) => {
    const { uid } = c.req.param();
    const { serverToken } = await c.req.json();

    const google = new GoogleProvider(c.env);

    const play = new GooglePlayProvider(google, "me.laknabil.voca");
    const purchase = await play.verifyPurchase(serverToken)


    if (purchase?.expiryTimeMillis) {
        const now = new Date().getTime();
        if (now < purchase.expiryTimeMillis) {
            await drizzle(c.env.DB).update(usersTable).set({
                claims: {
                    ...(purchase as any),
                    premiumExpires: parseInt(purchase.expiryTimeMillis)
                }
            }).where(eq(usersTable.uid, uid)).run();
            return c.json({ status: "success", message: "Purchase verified", purchase });
        }

    }

    return c.json({ status: "error", message: "Purchase expired", purchase }, 400);
});




export default PaymentAPI
