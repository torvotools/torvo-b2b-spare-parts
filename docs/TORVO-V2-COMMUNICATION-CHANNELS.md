# TORVO V2 COMMUNICATION CHANNELS

## APPROVED CHANNEL MODEL

1. WHATSAPP API — PRIMARY
   - Dealer/customer operational communication
   - Requirements and lead/referral notifications
   - Approved OTP/security flows where provider support is configured
   - Promotional messaging only with separate recorded marketing opt-in and opt-out support

2. PUBLIC BUSINESS EMAIL — SECONDARY
   - Website contact/requirement enquiries
   - Social-account business contact destination
   - Customer/dealer messages that are better suited to email
   - Must be Admin-configurable; do not hard-code a mailbox in public source

3. PRIVATE ADMIN EMAIL — INTERNAL/SECURITY ONLY
   - Owner/Admin account recovery and security notices
   - Domain/hosting/developer/store/account administration
   - Never expose on public Website, Dealer App, public API payloads or customer-facing profile

## FIVE IMPLEMENTATION RULES

1. CHANNEL PRIORITY
   WhatsApp is the default business communication path. Email must not silently replace WhatsApp for operational flows.

2. PUBLIC EMAIL SAFETY
   Public business email is a configurable support/contact value. Public UI may display it only when enabled by Admin.

3. ADMIN EMAIL PRIVACY
   Private Admin email is secret business contact data. It must remain server-authorized and excluded from public responses, exports intended for Dealers/Customers, client configuration and source-controlled environment files.

4. SOCIAL LEAD ROUTING
   Social profiles may point users to the public Website, SEND REQUIREMENT, WhatsApp or public business email. Leads entering through the Website should follow the same Customer/referral CRM rules and consent audit requirements as other public leads.

5. CONSENT + AUDIT
   A requirement/enquiry does not equal marketing consent. Store marketing consent separately with source/timestamp and opt-out status. Do not mark WhatsApp/email as sent until a real provider confirms the send.

## CONFIGURATION KEYS — DESIGN CONTRACT

- PUBLIC_BUSINESS_EMAIL: Admin-managed, public only when enabled.
- PUBLIC_BUSINESS_EMAIL_ENABLED: boolean.
- PRIVATE_ADMIN_EMAIL: privileged server-side setting; never public.
- PRIMARY_COMMUNICATION_CHANNEL: WHATSAPP.
- CUSTOMER_CARE_WHATSAPP: Admin-managed support number.

Do not commit actual private email credentials, provider secrets, passwords, OTP secrets or API tokens.
