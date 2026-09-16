# TORVO V2 CONTACT + SECURITY CHECKLIST

## RELEASE CHECKS

- [ ] WhatsApp provider/API configured outside source control.
- [ ] WhatsApp OTP runtime-tested before production claim.
- [ ] Public business email configured by Admin; no credential in client code.
- [ ] Private Admin email excluded from public/client payloads.
- [ ] Social links route to approved TORVO entry points.
- [ ] SEND REQUIREMENT records source only when known.
- [ ] Requirement/referral consent is not reused as marketing consent.
- [ ] Marketing opt-in source/timestamp and opt-out status are auditable.
- [ ] STOP/UNSUBSCRIBE path is practical and enforced.
- [ ] Customer/dealer notifications never claim SENT/DELIVERED without provider confirmation.
- [ ] Blocked/inactive users cannot use private communication actions.
- [ ] Role checks protect Dealer/private commercial and Admin/security contact data.
- [ ] Public APIs cannot enumerate customer/dealer contact databases.
- [ ] Logs redact passwords, OTPs, tokens and provider credentials.

## OWNER ACCEPTANCE
Production communication is ready only after real provider integration and staging/runtime verification. Documentation or UI presence alone is not proof of a working send/OTP flow.
