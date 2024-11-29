import { LightningElement, wire, api } from 'lwc';
import getForecastByBillingCity from '@salesforce/apex/WeatherForecastController.getForecastByBillingCity';
import { getRecord } from 'lightning/uiRecordApi';

const BILLING_CITY_FIELD = 'Account.BillingCity';

export default class ForecastByBillingCity extends LightningElement {
    @api recordId; // The ID of the current Account record
    weatherData = [];
    isLoading = false;

    // Get the Billing City from the Account record
    @wire(getRecord, { recordId: '$recordId', fields: [BILLING_CITY_FIELD] })
    account({ error, data }) {
        if (data) {
            const billingCity = data.fields.BillingCity.value;
            this.fetchWeatherData(billingCity);
        } else if (error) {
            console.error('Error fetching account data:', error);
        }
    }

    // Fetch the weather forecast for the Billing City
    fetchWeatherData(cityName) {
        this.isLoading = true;
        getForecastByBillingCity({ accountId: this.recordId })
            .then((result) => {
                this.weatherData = result;
                this.isLoading = false;
            })
            .catch((error) => {
                console.error('Error fetching weather data:', error);
                this.isLoading = false;
            });
    }
}
