public with sharing class WeatherController {

    @AuraEnabled(cacheable=true)
    public static List<WeatherData> getForecastByBillingCity(Id accountId) {
        // Check if the user has read access to the Account object
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new AuraHandledException('You do not have permission to access Account records.');
        }

        // Query the Billing City from the Account record, ensuring proper CRUD access
        Account account = [SELECT BillingCity 
                            FROM Account 
                            WHERE Id = :accountId LIMIT 1];
        String cityName = account.BillingCity;

        // Proceed to fetch the weather forecast for the city
        return getForecastByCity(cityName);
    }

    public class WeatherData {
        @AuraEnabled
        public String forecastDate;
        @AuraEnabled
        public String temperature;
        @AuraEnabled
        public String description;

        public WeatherData(String forecastDate, String temperature, String description) {
            this.forecastDate = forecastDate;
            this.temperature = temperature;
            this.description = description;
        }
    }

    // Fetch weather forecast by city name
    @AuraEnabled(cacheable=true)
    public static List<WeatherData> getForecastByCity(String cityName) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String endpoint = 'https://api.openweathermap.org/data/2.5/forecast?q=' + cityName + '&appid=9adb46131d11282a4e362a52d6018af1&units=metric';
        request.setEndpoint(endpoint);
        request.setMethod('GET');

        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            return parseWeatherResponse(response.getBody());
        } else {
            throw new AuraHandledException('Error fetching weather data: ' + response.getStatus());
        }
    }

    private static List<WeatherData> parseWeatherResponse(String responseBody) {
        List<WeatherData> forecastList = new List<WeatherData>();
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
        List<Object> forecasts = (List<Object>) result.get('list');
        Map<String, Boolean> daysProcessed = new Map<String, Boolean>();

        // Loop through the forecast data and add only one entry per day
        for (Object forecast : forecasts) {
            Map<String, Object> forecastMap = (Map<String, Object>) forecast;
            String forecastDateTime = (String) forecastMap.get('dt_txt'); 
            String forecastDate = forecastDateTime.split(' ')[0]; // Extract the date (YYYY-MM-DD)

            // Only add the forecast for the first occurrence of each day
            if (!daysProcessed.containsKey(forecastDate)) {
                daysProcessed.put(forecastDate, true); // Mark this day as processed
                Map<String, Object> main = (Map<String, Object>) forecastMap.get('main');
                String temp = String.valueOf(main.get('temp')); 
                List<Object> weather = (List<Object>) forecastMap.get('weather');
                String description = (String) ((Map<String, Object>) weather[0]).get('description');

                forecastList.add(new WeatherData(forecastDate, temp, description));
            }
        }

        return forecastList;
    }
}
