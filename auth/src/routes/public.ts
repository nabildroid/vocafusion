import { Hono } from 'hono'
import { CreateHono } from '..'
import { drizzle } from 'drizzle-orm/d1';
import { usersTable } from '../db/schema';
import { NowInSecond, generateID, isDumbOtp, tokenToOTP } from '../utils';
import { sign, verify } from 'hono/jwt'
import { eq } from 'drizzle-orm';
import { cors } from 'hono/cors';
import * as z from "zod"

import GoogleProvider from "../repositories/googleProvider"
import GooglePlayProvider from '../repositories/googlePlayProvider';
const PublicAPI = CreateHono();

// todo remove this
PublicAPI.use('*', cors())




const LoginWithGoogleSchmema = z.object({
    accessToken: z.string(),
    nativeLanguage: z.string().optional(),
});


PublicAPI.post("/loginWithGoogle", async (c) => {
    const ipAddress = c.req.header()["cf-connecting-ip"] || ""
    const { success } = await c.env.RATELIMIT_NEW_ACCOUNT.limit({ key: ipAddress })
    if (!success && process.env.NODE_ENV !== "development") {
        return c.json({ success: false, error: "Rate limit exceeded" }, { status: 429 })
    }

    const { accessToken, nativeLanguage } = LoginWithGoogleSchmema.parse(await c.req.json());
    if (!accessToken) {
        return c.json({ success: false, error: "Missing AccessToken" }, { status: 401 })
    }

    const google = new GoogleProvider(c.env);
    const googleUser = await google.getUser(accessToken);


    let user: any;

    try {
        user = await drizzle(c.env.DB).insert(usersTable).values({
            uid: generateID(),
            email: googleUser.email,
            displayName: googleUser.name,
            photoUrl: googleUser.picture,
            nativeLanguage: nativeLanguage!
        }).returning()





    } catch (e) {
        console.log(e)
        const query = await drizzle(c.env.DB).select().from(usersTable).where(eq(usersTable.email, googleUser.email))
        if (!query.length) {
            return c.json({ success: false, error: "User not found" }, { status: 404 })
        }
        user = query[0]

    }
    console.log(user);

    const tokenID = generateID();
    console.log(tokenID)

    const expires = NowInSecond() + 60 * 3600 * 30;

    const token = await sign({
        exp: expires,
        iat: NowInSecond(),
        iss: "vocafusion-auth-cloudflare",
        tokenID,
        ...user,
    }, "phpiscool")

    const refreshToken = await sign({
        exp: NowInSecond() + 60 * 3600 * 60,
        iat: NowInSecond(),
        iss: "vocafusion-auth-cloudflare",
        tokenID,
        uid: user.uid,
    }, "phpiscool-1")



    return c.json({ success, uid: user.uid, token, refreshToken, expires })
});




PublicAPI.post("/refresh", async (c) => {
    const { token } = await c.req.json()

    const payload = await verify(token, "phpiscool-1");

    if (!payload.exp || NowInSecond() > payload.exp) {
        return c.notFound()
    }

    const uid = payload.uid as string;

    const now = Date.now();
    const query = await drizzle(c.env.DB).select().from(usersTable).where(eq(usersTable.uid, uid));
    console.info(Date.now() - now + "ms");

    if (!query.length) {
        return c.notFound()
    }

    const user = query[0];

    // user.claims = {
    //     premiumExpires: Date.now() + 1000 * 60 * 60 * 24 * 30,
    // }


    const expires = NowInSecond() + 60 * 3600 * 30;

    const newToken = await sign({
        exp: expires,
        iat: NowInSecond(),
        iss: "vocafusion-auth-cloudflare",
        tokenID: payload.tokenID,
        ...user,
    }, "phpiscool")


    return c.json({ newToken, user, expires })
})


PublicAPI.post("/jwt", async (c) => {
    // todo if you can't distinguish between the jwt and refresh token people will kill you
    const { token } = await c.req.json()
    const payload = await verify(token, "phpiscool");

    if (!payload.exp || NowInSecond() > payload.exp || payload.iss != "vocafusion-auth-cloudflare") {
        return c.notFound()
    }

    return c.json({ user: payload })
})



export default PublicAPI