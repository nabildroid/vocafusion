import { Hono } from 'hono'
import { CreateHono } from '..';
import { drizzle } from 'drizzle-orm/d1';
import { usersTable } from '../db/schema';
import { eq } from 'drizzle-orm';
import { sign } from 'hono/jwt';
import { NowInSecond, generateID } from '../utils';
import { HTTPException } from 'hono/http-exception';


const ServiceAPI = CreateHono();


ServiceAPI.use(async (c, next) => {
    console.log(c.env)
    if (c.req.header()["key"] != "79253750d90bbab380d368bce7a1de51")
        return c.redirect("https://etre.pro")

    return await next()
})


/// create a user
ServiceAPI.post("/create", (c) => {
    return c.json({})
})


// get a jwt
ServiceAPI.get("/jwt/:uid", async (c) => {
    const { uid } = c.req.param()

    const user = await drizzle(c.env.DB).select().from(usersTable).where(eq(usersTable.uid, uid)).get()

    if (!user)
        return c.notFound()



    const tokenID = generateID();
    console.log(tokenID)


    const token = await sign({
        exp: NowInSecond() + 60 * 15,
        iat: NowInSecond(),
        iss: "vocafusion-auth-cloudflare",
        tokenID,
        ...user,
    }, "phpiscool")



    const refreshToken = await sign({
        exp: NowInSecond() + 60 * 60 * 24 * 30,
        iat: NowInSecond(),
        iss: "vocafusion-auth-cloudflare",
        tokenID,
        uid,
    }, "phpiscool-1")



    return c.json({ token, refreshToken })
})

// Manipulation
ServiceAPI.post("claim/:uid", async (c) => {

    const { uid } = c.req.param()
    const claims = await c.req.json()


    if (!Object.keys(claims).length) {
        throw new HTTPException(401, { message: 'please provide the key and the value for the claim' })
    }

    const user = await drizzle(c.env.DB).select().from(usersTable).where(eq(usersTable.uid, uid)).get()
    if (!user)
        return c.notFound();




    await drizzle(c.env.DB).update(usersTable).set({
        claims: {
            ...(user.claims ?? {}),
            ...claims
        }
    })

    return c.json({})
})




ServiceAPI.post("claims/:uid", async (c) => {


    const { uid } = c.req.param()
    const claims = await c.req.json()

    if (!Object.keys(claims).length) {
        throw new HTTPException(401, { message: 'please provide the claims' })
    }

    const user = await drizzle(c.env.DB).select().from(usersTable).where(eq(usersTable.uid, uid)).get()
    if (!user)
        return c.notFound();


    if (!user.claims)
        user.claims = {} as any;
    (user.claims as any) = claims


    await drizzle(c.env.DB).update(usersTable).set({
        claims: user.claims
    })

    return c.json({})
})

ServiceAPI.get("claims/:uid", async (c) => {
    const { uid } = c.req.param()

    const user = await drizzle(c.env.DB).select().from(usersTable).where(eq(usersTable.uid, uid)).get()
    if (!user)
        return c.notFound();



    return c.json({
        ...(user.claims ?? {})
    })
})








// ServiceAPI.post("setSite/:uid", async (c) => {
//     const { uid } = c.req.param()
//     const { site } = await c.req.json()

//     console.log({ uid, site })
//     await drizzle(c.env.DB).update(usersTable).set({
//         site: site
//     }).where(eq(usersTable.uid, uid));

//     return c.json({ done: true })
// })






ServiceAPI.post()

export default ServiceAPI;