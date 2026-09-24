# TORVO V2 COMMUNICATION CHANNELS

## FINAL CHANNEL MODEL

1. EMAIL OTP — AUTHENTICATION ONLY
   - Dealer authentication uses the Dealer's own approved registered email address as the login identity.
   - Dealer login is passwordless: SEND OTP -> 6-digit email OTP -> authenticated native-app session.
   - Dealer OTP is required on first login, after Logout, after uninstall/reinstall, on a new device, or after a security/session revoke. Normal app reopen must not repeatedly request OTP while the valid device session remains.
   - Staff/Admin/Accountant/Salesman/Store Keeper OTP uses the separate Owner-controlled master staff OTP email contract.
   - WhatsApp MUST NOT be used for login OTP, PIN recovery, password recovery, or any authentication/security verification.

2. WHATSAPP CHANNEL A — DEALER/CUSTOMER -> TORVO
   - Requirements, spare-part enquiries, photos, model/details and normal business messages.
   - This is a communication/inquiry channel, never an authentication channel.

3. WHATSAPP CHANNEL B — TORVO -> DEALER/CUSTOMER
   - Invoice/estimate notifications, dispatch/delivery updates, invitations, new-item links/photos, schemes, offers and approved announcements.
   - Owner/Admin and Accountant may control authorized business communication.
   - Salesman has SEND-ONLY permission and only for Dealers/areas mapped to that Salesman. Salesman cannot change provider/API credentials, channel configuration, templates/settings, consent controls, or unrestricted recipient mappings.
   - Financial documents sent on WhatsApp are notifications/copies only. TORVO database records remain authoritative.

## NEW DEALER WELCOME + FIRST LOGIN

- After a Dealer registration is approved, send a Welcome message to the Dealer's registered email.
- The welcome message tells the Dealer to use that registered email as the TORVO App login identity.
- First login: registered email -> eligibility confirmed -> SEND OTP TO REGISTERED EMAIL -> OTP sent to that Dealer email -> VERIFY OTP & LOGIN.
- Do not disclose private Dealer data merely to confirm whether an email is registered.
- OTP must be single-use, expire, be rate-limited, and be verified server-side.

## COMMUNICATION RULES

1. AUTH/COMMUNICATION SEPARATION
   Email OTP authentication and WhatsApp business communication are separate systems. A WhatsApp delivery or reply must never establish an authenticated TORVO session.

2. TWO WHATSAPP PURPOSES
   Keep inbound requirement/support communication separate from outbound company communication so routing, permissions, templates, consent and audit can be controlled independently.

3. ROLE CONTROL
   Owner/Admin control configuration. Accountant may use authorized outbound operational/financial communication. Salesman is send-only to mapped Dealers. Dealer/customer uses the inbound requirement/support path.

4. CONSENT + AUDIT
   A requirement/enquiry does not equal marketing consent. Promotional/scheme messaging requires the applicable recorded consent/opt-out controls. Do not mark a WhatsApp/email as sent until a real provider confirms delivery/submission according to the provider contract.

5. SECRET SAFETY
   Provider credentials, private security mailboxes, API tokens and OTP secrets remain server-side and must never be committed to public/client source.

## CONFIGURATION DESIGN CONTRACT

- DEALER_AUTH_CHANNEL: EMAIL_OTP
- STAFF_AUTH_CHANNEL: MASTER_EMAIL_OTP
- WHATSAPP_INBOUND_REQUIREMENT_CHANNEL: Admin-managed
- WHATSAPP_OUTBOUND_COMPANY_CHANNEL: Admin-managed
- CUSTOMER_CARE_WHATSAPP: Admin-managed support number
- PUBLIC_BUSINESS_EMAIL: Admin-managed public contact value when enabled

Do not commit actual private email credentials, provider secrets, passwords, OTP secrets or API tokens.
