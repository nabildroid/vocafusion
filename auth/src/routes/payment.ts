import { cors } from "hono/cors";
import { CreateHono } from "..";
import { drizzle } from 'drizzle-orm/d1';
import { ChargilyClient } from '@chargily/chargily-pay';
import { usersTable } from "../db/schema";
import { eq } from 'drizzle-orm';
import { analytics } from "../utils";

const gate = new ChargilyClient({
    api_key: 'test_sk_n1O6YHs72Jv5LDh4fl8tA6M2WaYC4MZ2FJ4WGvbH',
    mode: 'test', // Change to 'live' when deploying your application
});

const PaymentAPI = CreateHono();
PaymentAPI.use('*', cors())



PaymentAPI.get("/:uid", async (c) => {
    const { uid } = c.req.param();
    const user = await drizzle(c.env.DB).select().from(usersTable).where(eq(usersTable.uid, uid)).get()

    if (!user) {
        return c.json({ message: "user not found" }, { status: 404 })
    }

    if (user.claims?.premiumExpires) {
        const now = new Date().getTime();
        if (now < user.claims.premiumExpires) {
            return c.json({ status: "error", message: "User already has premium" });
        }
    }


    const link = await gate.createCheckout({
        success_url: "https://vocafusion.laknabil.me/payment",
        amount: 2000,
        currency: "dzd",
        description: "Monthly susbcriptions",
        metadata: {
            uid,
        },
        locale: "ar",
    })

    return c.redirect(link.checkout_url);
});



PaymentAPI.post("/webhook", async (c) => {
    const body = await c.req.json();
    console.log(body);
    if (body.type != "checkout.paid") return c.json({ status: "error", message: "Invalid event type" });

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



export default PaymentAPI
