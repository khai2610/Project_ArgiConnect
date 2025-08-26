const String baseUrl = 'http://10.0.2.2:5000/api'; // <-- thay bằng domain thực tế
const String authRegisterEndpoint = '$baseUrl/auth/register';
const String authLoginEndpoint = '$baseUrl/auth/login';

const String createRequestEndpoint = '$baseUrl/farmer/requests';
const String farmerProfileEndpoint = '$baseUrl/farmer/profile';
const String approvedProvidersUrl = '$baseUrl/farmer/list-services';
const String farmerInvoiceEndpoint = '$baseUrl/farmer/invoices';
String getFarmerInvoiceDetailUrl(String id) => '$baseUrl/farmer/invoices/$id';
String getFarmerInvoicePayUrl(String id) => '$baseUrl/farmer/invoices/$id/pay';

String getPublicProviderInfoUrl(String id) => '$baseUrl/public/provider/$id';
String getPublicProviderServicesUrl(String id) =>'$baseUrl/public/provider/$id/services';

const String publicProvidersUrl = '$baseUrl/public/providers';

const String providerProfileEndpoint = '$baseUrl/provider/profile';
const String providerRequestEndpoint = '$baseUrl/provider/requests';
const String providerServiceEndpoint = '$baseUrl/provider/services';
const String providerInvoiceEndpoint = '$baseUrl/provider/invoices';
const String providerSummaryEndpoint = '$baseUrl/provider/requests/summary';

const String chatBaseUrl = '$baseUrl/chat';

String getChatMessagesUrl(String requestId) => '$chatBaseUrl/$requestId';
const String chatConversationsUrl = chatBaseUrl;

String getChatBetweenUrl(String farmerId, String providerId) =>'$chatBaseUrl/between/$farmerId/$providerId';
const String sendMessageUrl = chatBaseUrl;

const String farmerRole = 'farmer';
const String providerRole = 'provider';
