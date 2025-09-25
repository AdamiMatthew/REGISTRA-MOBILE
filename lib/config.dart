//const url = "http://192.168.100.3:4000/api/";
 const url = "https://registra-b7181b9e50a0.herokuapp.com/api/";

//user
const registration = "${url}mobile-user/registration";
const login = "${url}mobile-user/login";
const homescreen = "${url}mobile-user/homescreen";
const verification = "${url}mobile-user/verification";
const sendOTP = "${url}mobile-user/sendOTP";
const resendOtpUrl  = "${url}mobile-user/resendOTP";
const resetverifyOTP = "${url}mobile-user/resetverifyOTP";
const resetPassword = "${url}mobile-user/resetPassword";
const checkEmail = "${url}mobile-user/check_Email";
const allevents = "${url}mobile-events/events";
const eventDetail = "${url}mobile-events/events/geteventdetails";
const register = "${url}mobile-events/events" + "/event_register";
const update = "${url}mobile-user/updateProfile";
const registered = "${url}mobile-events/events/events_registered";
const registeredPast = "${url}mobile-events/events/registered_past";
const ticket = "${url}mobile-events/events/events_registered/ticket";
//admin
// const adminLogin = "${url}mobile/admin-login";

// Additional URLs
const attendanceUpdate = "${url}admin/attendance/update";
const certTemplate = "${url}certificate/template";
const certificateUser = "${url}certificate/user";
const feedbackGet = "${url}feedback/getFeedback";
const feedbackSubmit = "${url}mobile-feedback/submitFeedback";
const feedbackCheck = "${url}mobile-feedback/checkSubmission";
const checkEmailExists = "${url}mobile-user/check-email";
const eventCertificate = "${url}certificate/event_certificate";