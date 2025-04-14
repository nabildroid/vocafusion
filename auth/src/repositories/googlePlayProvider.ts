import type GoogleProvider from "./googleProvider";



type Price = {
    amountMicros: string;
    currencyCode: string;
};

type PhaseRegionalConfig = {
    regionCode: string;
    price?: Price;
    free?: {}; // Indicates a free phase for the region
};

type PhaseOtherRegionsConfig = {
    price?: Price;
    free?: {}; // Indicates a free phase for other regions
};

type OfferPhase = {
    recurrenceCount?: number; // How many times this phase repeats (optional)
    duration: string; // ISO 8601 duration format (e.g., "P1M", "P3D")
    regionalConfigs?: PhaseRegionalConfig[]; // Region-specific pricing/free status for this phase
    otherRegionsConfig?: PhaseOtherRegionsConfig; // Default pricing/free status for regions not listed above
};

type OfferRegionalConfig = {
    regionCode: string;
    newSubscriberAvailability?: boolean; // Whether the offer is available to new subscribers in this region
};

type OfferTargetingScope = {
    anySubscriptionInApp?: {}; // Example targeting scope
    // Add other potential scope types here if known, or use a general index signature
    [key: string]: any;
};

type OfferTargetingAcquisitionRule = {
    scope?: OfferTargetingScope;
};

type OfferTargeting = {
    acquisitionRule?: OfferTargetingAcquisitionRule;
};

type OfferOtherRegionsConfig = {
    otherRegionsNewSubscriberAvailability?: boolean; // Default availability for new subscribers in regions not listed
};

type SubscriptionOffer = {
    packageName: string;
    productId: string; // The subscription product ID
    basePlanId: string; // The base plan ID this offer belongs to
    offerId: string; // The unique ID for this offer
    state: string; // e.g., "ACTIVE", "INACTIVE", "DRAFT"
    phases: OfferPhase[]; // The different phases of the offer (e.g., free trial, introductory price, regular price)
    regionalConfigs?: OfferRegionalConfig[]; // Region-specific availability for the entire offer
    targeting?: OfferTargeting; // Rules defining who is eligible for the offer
    otherRegionsConfig?: OfferOtherRegionsConfig; // Default availability for the offer in regions not explicitly listed
};


// Price specific to the Subscription resource (uses units/nanos)
type SubscriptionPrice = {
    currencyCode: string;
    units?: string; // Optional as it might not be present if nanos is
    nanos?: number; // Optional as it might not be present if units is
};

// Regional configuration for a Base Plan
type BasePlanRegionalConfig = {
    regionCode: string;
    newSubscriberAvailability: boolean;
    price: SubscriptionPrice;
};

// Configuration for auto-renewing base plans
type AutoRenewingBasePlanType = {
    billingPeriodDuration: string; // ISO 8601 duration
    gracePeriodDuration?: string; // ISO 8601 duration (optional)
    resubscribeState: string; // e.g., "RESUBSCRIBE_STATE_ACTIVE"
    prorationMode: string; // e.g., "SUBSCRIPTION_PRORATION_MODE_CHARGE_ON_NEXT_BILLING_DATE"
    legacyCompatible?: boolean;
    legacyCompatibleSubscriptionOfferId?: string;
    accountHoldDuration?: string; // ISO 8601 duration (optional)
};

// Configuration for regions not explicitly listed in a Base Plan
type BasePlanOtherRegionsConfig = {
    usdPrice?: SubscriptionPrice;
    eurPrice?: SubscriptionPrice;
    newSubscriberAvailability: boolean;
};

// Represents a base plan within a subscription product
type BasePlan = {
    basePlanId: string;
    regionalConfigs?: BasePlanRegionalConfig[];
    state: string; // e.g., "ACTIVE", "INACTIVE", "DRAFT"
    autoRenewingBasePlanType?: AutoRenewingBasePlanType; // Present for auto-renewing plans
    otherRegionsConfig?: BasePlanOtherRegionsConfig;
};

// Represents localized listing details for a subscription
type SubscriptionListing = {
    title: string;
    languageCode: string;
};



// Represents a Google Play Subscription Product
type Subscription = {
    packageName: string;
    productId: string;
    basePlans: BasePlan[];
    listings: SubscriptionListing[];
};



export type IPlayOffer = {
    basePlanId: string;
    packageName: string;
    productId: string;
    offerId?: string;
    freeTrailDuration: number;
    periodInDays: number;
    usdPrice: number;
    isSubscription: boolean;
}

export default class GooglePlayProvider {
    private googleClient: GoogleProvider;
    public packageName: string;
    private token: string | null = null;

    constructor(googleClient: GoogleProvider, packageName: string) {
        this.packageName = packageName;
        this.googleClient = googleClient;
    }



    async getToken() {
        this.token = this.token ?? await this.googleClient.getGoogleAccessToken([
            "https://www.googleapis.com/auth/androidpublisher",
        ]);
        return this.token;
    }


    async getSubscriptions() {
        const response = await fetch(
            `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${this.packageName}/subscriptions`,
            {
                headers: {
                    Authorization: `Bearer ${await this.getToken()}`,
                },
            }
        );

        const data = await response.json();
        console.debug("got subscriptions", data);
        return (data as any).subscriptions as Subscription[];
    }


    async getSubscriptionOffer(productId: string, basePlanId: string) {
        const response = await fetch(
            `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${this.packageName}/subscriptions/${productId}/basePlans/${basePlanId}/offers`,
            {
                headers: {
                    Authorization: `Bearer ${await this.getToken()}`,
                },
            }
        );

        const data = await response.json();

        return (data as any).subscriptionOffers as SubscriptionOffer[];
    }



    async getOffers() {
        const subscription = (await this.getSubscriptions())[0];

        const offers = await Promise.all(subscription.basePlans.map(async e => {
            if (e.state != "ACTIVE") return null;

            const offers = await this.getSubscriptionOffer(subscription.productId, e.basePlanId);
            const offer = offers[0];

            const freeTrialPhase = offer.phases.find((phase) => !!phase.otherRegionsConfig?.free);
            const freeTrialDuration = freeTrialPhase ? convertPeriodToDay(freeTrialPhase.duration) : 0;



            return {
                basePlanId: e.basePlanId,
                packageName: this.packageName,
                productId: subscription.productId,
                offerId: offer.offerId,
                freeTrailDuration: offer.state == "ACTIVE" ? freeTrialDuration : 0,
                periodInDays: convertPeriodToDay(e.autoRenewingBasePlanType?.billingPeriodDuration!),
                usdPrice: parseInt(e.otherRegionsConfig?.usdPrice?.units ?? "0", 10) + (e.otherRegionsConfig?.usdPrice?.nanos ?? 0) / 1e9,
                isSubscription: true
            } as IPlayOffer;


        }));


        return offers.filter(Boolean) as IPlayOffer[]
    }
}



function convertPeriodToDay(period: string) {

    const match = period.match(/P(\d+)([YWMD])/);
    if (match) {
        const value = parseInt(match[1], 10);
        const unit = match[2];
        switch (unit) {
            case 'Y':
                return value * 365; // Convert years to days
            case 'M':
                return value * 30; // Convert months to days (approximation)
            case 'W':
                return value * 30; // Convert months to days (approximation)
            case 'D':
                return value; // Days
            default:
                return 0;
        }
    }
    return 0;

}