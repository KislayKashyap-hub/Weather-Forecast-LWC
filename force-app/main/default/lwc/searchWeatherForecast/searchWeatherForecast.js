import { LightningElement, track } from 'lwc';
import  getForecastByCity from '@salesforce/apex/WeatherForecastController.getForecastByCity';
export default class SearchWeatherForecoast extends LightningElement {
    @track cityName = '';
    @track weatherData = [];
    @track isLoading = false;

    handleInputChange(event) {
        this.cityName = event.target.value;
    }

    fetchWeatherData() {
        if (!this.cityName) {
            alert('Please enter a city name.');
            return;
        }
        this.isLoading = true;
        getForecastByCity({ cityName: this.cityName })
            .then(result => {
                this.weatherData = result;
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching weather data:', error);
                this.isLoading = false;
                alert('There was an error fetching the weather data. Please check the city name and try again.');
            });
    }
    
}
