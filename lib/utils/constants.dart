const String baseUrl =
    'http://10.0.2.2:5000/api'; // <-- thay bằng domain thực tế
const String authRegisterEndpoint = '$baseUrl/auth/register';
const String authLoginEndpoint = '$baseUrl/auth/login';

const String createRequestEndpoint = '$baseUrl/farmer/requests';
const String farmerProfileEndpoint = '$baseUrl/farmer/profile';
const String approvedProvidersUrl = '$baseUrl/farmer/list-services';

const String providerProfileEndpoint = '$baseUrl/provider/profile';
const String providerRequestEndpoint = '$baseUrl/provider/requests';
const String providerServiceEndpoint = '$baseUrl/provider/services';
const String providerInvoiceEndpoint = '$baseUrl/provider/invoices';

const String farmerRole = 'farmer';
const String providerRole = 'provider';
