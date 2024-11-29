import { LightningElement, api } from 'lwc';

export default class WeatherTableForecast extends LightningElement {
    @api weatherData;
}
