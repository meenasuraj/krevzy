# Database Draft

## users
- id
- displayName
- email/phone identifier
- photoUrl
- createdAt
- updatedAt

## notes
- id
- ownerId
- title
- content
- createdAt
- updatedAt
- deletedAt (optional soft-delete workflow)

## media
- id
- ownerId
- storagePath
- mediaType
- size
- checksum
- scanStatus
- createdAt

## payments
- id
- ownerId
- providerOrderId
- providerPaymentId
- amount
- currency
- status
- createdAt

## security_events
- id
- ownerId
- eventType
- severity
- createdAt

The final schema will be adapted to the selected backend and security rules.
