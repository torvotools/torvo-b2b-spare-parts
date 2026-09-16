# TORVO V2 COMMUNICATION ADMIN CONTRACT

## OWNER / ADMIN SETTINGS
Admin workspace should provide controlled settings for:
- PUBLIC BUSINESS EMAIL + ENABLE/DISABLE DISPLAY
- CUSTOMER CARE WHATSAPP NUMBER
- SOCIAL PROFILE LINKS
- CUSTOMER REQUIREMENT CHANNEL AVAILABILITY

PRIVATE ADMIN EMAIL is Owner/security configuration and must not be exposed to normal Admin/Dealer/Customer surfaces unless explicitly authorized by the security model.

## VALIDATION
- Validate email format server-side before activation.
- Validate support phone/WhatsApp number before activation.
- Normalize social URLs and allow only expected safe HTTPS destinations.
- Audit material configuration changes with actor and timestamp.
- Never store provider/API credentials in a public settings table or return them to clients.

## FALLBACK
If WhatsApp provider is unavailable, show a truthful alternative such as SEND REQUIREMENT, CALL CUSTOMER CARE or PUBLIC BUSINESS EMAIL when enabled. Never show a successful WhatsApp send state if no provider confirmation exists.
