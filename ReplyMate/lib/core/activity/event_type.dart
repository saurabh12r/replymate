/// Call activity kinds for the activity log (persisted as index — do not reorder).
enum EventType {
  incomingCall,
  missedCall,
  whatsappCall,
  busyCall,
  rejectedCall,
  outgoingAnswered,
  outgoingUnanswered,
  scheduledSms,
}
