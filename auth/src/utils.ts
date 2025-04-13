


export function generateID() {
    return crypto.randomUUID().replaceAll("-", "").slice(0, 10)
}





export function NowInSecond() {
    return Math.floor(Date.now() / 1000)
}





export async function tokenToOTP(token: string, phone: string) {
    const data = JSON.parse(await Decrypt(token)) as {
        phone: string,
        otp: number,
        timestamp: number,
        expires: number
    };


    console.log(phone, data)
    // todo endWith is very bad and unsecure, make sure to capture the +country code

    const parsedPhone = phone.replace(/^0/, "");
    if (!data.phone.endsWith(parsedPhone)) throw new Error("Invalid Phone Number");
    if (data.expires < Date.now()) throw new Error("Token Expired");

    return data.otp;
}





export async function Decrypt(str: string) {


    async function getCryptoParams() {
        const key_string = 'caac9e095599b7e8709a0c2173de8fb2bc20bfc455c0b7fbced7dacb2a217331';
        const iv_string = 'd5a40b7e337c7b39fc28ea7e52056ded';


        const key = await crypto.subtle.importKey(
            "raw",
            hexToArrayBuffer(key_string),
            { name: "AES-CBC" },
            false,
            ["encrypt", "decrypt"]
        );
        const iv = hexToArrayBuffer(iv_string);
        return { key, iv }
    }


    // Helper function to convert hex string to ArrayBuffer
    function hexToArrayBuffer(hexString: string) {
        const bytes = new Uint8Array(hexString.length / 2);
        for (let i = 0; i < hexString.length; i += 2) {
            bytes[i / 2] = parseInt(hexString.substring(i, i + 2), 16);
        }
        return bytes.buffer;
    }




    const { key, iv } = await getCryptoParams();
    const encryptedBytes = hexToArrayBuffer(str)
    const decryptedBytes = await crypto.subtle.decrypt(
        { name: 'AES-CBC', iv: iv },
        key,
        encryptedBytes
    );

    const decoder = new TextDecoder();
    const decryptedText = decoder.decode(decryptedBytes);
    return decryptedText;

}


export function isDumbOtp(otp: number) {
    return otp === 111111 || otp === 222222 || otp === 333333 || otp === 444444;
}





export async function analytics(props: {
    userId: string,
    event: string,
    properties: Record<string, any>
}) {
    try {
        const reponse = await fetch(
            'https://eu.i.posthog.com/capture/',
            {
                method: 'POST',
                body: JSON.stringify({
                    "api_key": "phc_qKJNHn1RX2l75TYuzvr2zbToLu2ilYTI1n8k6lTqXIK",
                    "event": props.event,
                    "distinct_id": props.userId,
                    "properties": props.properties
                }),
                headers: {
                    "Content-Type": "application/json"
                }
            }
        )

    } catch (e) {

    }
}