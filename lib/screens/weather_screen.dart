import 'package:flutter/material.dart';
import '../theme/brand_colors.dart';
import '../widgets/header.dart'; // Import Header widget

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _weatherData;
  List<dynamic>? _forecastData;
  String _errorMessage = '';
  final String _location = 'Kinston, NC'; // Default location

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // This would typically use your actual API key and endpoints
      // Replace with your actual OpenWeatherMap API key or similar service
      const apiKey = 'YOUR_API_KEY';
      final currentUrl =
          'https://api.openweathermap.org/data/2.5/weather?q=$_location&units=imperial&appid=$apiKey';
      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?q=$_location&units=imperial&appid=$apiKey';

      // For demo purposes, using mock data
      await Future.delayed(const Duration(seconds: 1));
      _weatherData = _getMockCurrentWeather();
      _forecastData = _getMockForecast();

      // In a real app, you would use:
      // final currentResponse = await http.get(Uri.parse(currentUrl));
      // final forecastResponse = await http.get(Uri.parse(forecastUrl));
      // _weatherData = jsonDecode(currentResponse.body);
      // _forecastData = jsonDecode(forecastResponse.body)['list'];
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load weather data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mock data for demonstration
  Map<String, dynamic> _getMockCurrentWeather() {
    return {
      "main": {
        "temp": 72.5,
        "feels_like": 74.2,
        "temp_min": 68.8,
        "temp_max": 75.6,
        "humidity": 65
      },
      "weather": [
        {"main": "Clear", "description": "clear sky", "icon": "01d"}
      ],
      "wind": {"speed": 8.5},
      "name": "Kinston"
    };
  }

  List<dynamic> _getMockForecast() {
    return [
      {
        "dt": DateTime.now()
                .add(const Duration(hours: 3))
                .millisecondsSinceEpoch /
            1000,
        "main": {
          "temp": 74.2,
        },
        "weather": [
          {"main": "Clear", "icon": "01d"}
        ]
      },
      {
        "dt": DateTime.now()
                .add(const Duration(hours: 6))
                .millisecondsSinceEpoch /
            1000,
        "main": {
          "temp": 76.8,
        },
        "weather": [
          {"main": "Clouds", "icon": "03d"}
        ]
      },
      {
        "dt": DateTime.now()
                .add(const Duration(hours: 9))
                .millisecondsSinceEpoch /
            1000,
        "main": {
          "temp": 72.3,
        },
        "weather": [
          {"main": "Clouds", "icon": "04d"}
        ]
      },
      {
        "dt": DateTime.now()
                .add(const Duration(hours: 12))
                .millisecondsSinceEpoch /
            1000,
        "main": {
          "temp": 68.1,
        },
        "weather": [
          {"main": "Clear", "icon": "01n"}
        ]
      },
      {
        "dt": DateTime.now()
                .add(const Duration(hours: 24))
                .millisecondsSinceEpoch /
            1000,
        "main": {
          "temp": 75.2,
        },
        "weather": [
          {"main": "Rain", "icon": "10d"}
        ]
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Use the Header widget here
          const Header(
            title: 'Weather',
            showDropdown:
                false, // Don't show category dropdown on weather screen
          ),

          // Refresh button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchWeatherData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.gold,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Weather content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: BrandColors.gold))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : _buildWeatherContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    if (_weatherData == null) {
      return const Center(child: Text('No weather data available'));
    }

    final currentTemp = _weatherData!['main']['temp'];
    final condition = _weatherData!['weather'][0]['main'];
    final feelsLike = _weatherData!['main']['feels_like'];
    final humidity = _weatherData!['main']['humidity'];
    final windSpeed = _weatherData!['wind']['speed'];
    final cityName = _weatherData!['name'];
    final weatherIcon = _weatherData!['weather'][0]['icon'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BrandColors.gold,
                  BrandColors.gold.withOpacity(0.6),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  cityName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateTime.now().toString().substring(0, 10),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://openweathermap.org/img/wn/$weatherIcon@2x.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.cloud,
                          size: 80,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${currentTemp.toStringAsFixed(1)}°F',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          condition,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeatherDetail(
                      'Feels Like',
                      '${feelsLike.toStringAsFixed(1)}°F',
                      Icons.thermostat,
                    ),
                    _buildWeatherDetail(
                      'Humidity',
                      '$humidity%',
                      Icons.water_drop,
                    ),
                    _buildWeatherDetail(
                      'Wind',
                      '${windSpeed.toStringAsFixed(1)} mph',
                      Icons.air,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hourly Forecast',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: _forecastData != null
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _forecastData!.length,
                    itemBuilder: (context, index) {
                      final forecast = _forecastData![index];
                      final time = DateTime.fromMillisecondsSinceEpoch(
                          (forecast['dt'] * 1000).toInt());
                      final temp = forecast['main']['temp'];
                      final weatherIcon = forecast['weather'][0]['icon'];

                      return Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${time.hour}:00',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Image.network(
                              'https://openweathermap.org/img/wn/$weatherIcon.png',
                              width: 40,
                              height: 40,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.cloud, size: 40),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${temp.toStringAsFixed(1)}°F',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : const Center(child: Text('No forecast available')),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Daily Forecast',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDailyForecastRow(
                  'Today',
                  72,
                  84,
                  Icons.wb_sunny,
                ),
                const Divider(),
                _buildDailyForecastRow(
                  'Tomorrow',
                  68,
                  79,
                  Icons.cloud,
                ),
                const Divider(),
                _buildDailyForecastRow(
                  'Wednesday',
                  65,
                  76,
                  Icons.water_drop,
                ),
                const Divider(),
                _buildDailyForecastRow(
                  'Thursday',
                  70,
                  82,
                  Icons.wb_sunny,
                ),
                const Divider(),
                _buildDailyForecastRow(
                  'Friday',
                  73,
                  85,
                  Icons.wb_sunny,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecastRow(String day, int low, int high, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(
            icon,
            color: BrandColors.gold,
            size: 24,
          ),
          Text(
            'Low: $low°F',
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          Text(
            'High: $high°F',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
