//https://gist.github.com/markelliot/6627143be1fc8209c9662c504d0ff205?permalink_comment_id=5504900#gistcomment-5504900
const { subtle } = globalThis.crypto;

const PEM_HEADER = '-----BEGIN PRIVATE KEY-----';
const PEM_FOOTER = '-----END PRIVATE KEY-----';

function objectToBase64url(object: object): string {
    return arrayBufferToBase64Url(new TextEncoder().encode(JSON.stringify(object)) as unknown as ArrayBuffer);
}

function arrayBufferToBase64Url(buffer: ArrayBuffer) {
    return btoa(String.fromCharCode(...new Uint8Array(buffer)))
        .replace(/=/g, '')
        .replace(/\+/g, '-')
        .replace(/\//g, '_');
}

function str2ab(str: string) {
    const buf = new ArrayBuffer(str.length);
    const bufView = new Uint8Array(buf);
    for (let i = 0, strLen = str.length; i < strLen; i += 1) {
        bufView[i] = str.charCodeAt(i);
    }
    return buf;
}

async function sign(content: string, signingKey: string) {
    const buf = str2ab(content);
    const plainKey = signingKey
        .replace(/(\r\n|\n|\r)/gm, '')
        .replace(/\\n/g, '')
        .replace(PEM_HEADER, '')
        .replace(PEM_FOOTER, '')
        .trim();

    const binaryKey = str2ab(atob(plainKey));
    const signer = await subtle.importKey(
        'pkcs8',
        binaryKey,
        {
            name: 'RSASSA-PKCS1-V1_5',
            hash: { name: 'SHA-256' },
        },
        false,
        ['sign'],
    );
    const binarySignature = await subtle.sign({ name: 'RSASSA-PKCS1-V1_5' }, signer, buf);
    return arrayBufferToBase64Url(binarySignature);
}

export async function getGoogleAuthToken(
    credentials: {
        private_key: string;
        client_email: string;
    },
    scopes: string[],
) {
    const { client_email: user, private_key: key } = credentials;
    const scope = scopes.join(' ');
    const jwtHeader = objectToBase64url({ alg: 'RS256', typ: 'JWT' });

    try {
        const assertiontime = Math.round(Date.now() / 1000);
        const expirytime = assertiontime + 3600;
        const claimset = objectToBase64url({
            iss: user,
            scope,
            aud: 'https://oauth2.googleapis.com/token',
            exp: expirytime,
            iat: assertiontime,
        });

        const jwtUnsigned = `${jwtHeader}.${claimset}`;
        const signedJwt = `${jwtUnsigned}.${await sign(jwtUnsigned, key)}`;
        const body = `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${signedJwt}`;

        const response = await fetch('https://oauth2.googleapis.com/token', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Cache-Control': 'no-cache',
                Host: 'oauth2.googleapis.com',
            },
            body,
        });

        const resp = (await response.json()) as { access_token: string };
        return resp.access_token;
    } catch (e) {
        console.error(e);
        throw e;
    }
}



export default class GoogleProvider {
    private googleClientEmail: string;
    private googlePrivateKey: string;

    private token: string | null = null;

    constructor(auth: {
        GOOGLE_CLIENT_EMAIL: string;
        GOOGLE_PRIVATE_KEY: string;
    }) {
        this.googleClientEmail = auth.GOOGLE_CLIENT_EMAIL;
        this.googlePrivateKey = auth.GOOGLE_PRIVATE_KEY;
    }

    async getGoogleAccessToken(scopes: string[] = []) {
        if (this.token && scopes.length == 0) return this.token;
        const auth = await getGoogleAuthToken({
            private_key: this.googlePrivateKey,
            client_email: this.googleClientEmail
        }, ["openid", "email", "profile", ...scopes]);

        this.token = auth;
        return auth;
    }



    async getUser(token: string, allowUnverifiedEmail = false) {
        console.time("GoogleUserFetcher")
        const response = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
            method: 'GET',
            headers: {
                Authorization: `Bearer ${token}`,
                'Content-Type': 'application/json',
                'Cache-Control': 'no-cache',
                Host: 'www.googleapis.com',
            },
        });
        console.timeEnd("GoogleUserFetcher")
        const data = await response.json() as {
            sub: string;
            name: string;
            given_name: string;
            family_name: string;
            picture: string;
            email: string;
            email_verified: boolean;
            hd?: string;
        };

        if (!allowUnverifiedEmail && !data.email_verified) {
            throw new Error("Email not verified");
        }

        return data;
    }
}