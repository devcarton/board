import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { Line } from 'react-chartjs-2';
import { Card, CardContent } from '@/components/ui/card';
import { Button, Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/button';
import { Sun, Moon, Bell, Wallet } from 'lucide-react';
import { calculateRSI, calculateMACD, calculateBollingerBands, calculateFibonacciRetracement, predictPrice } from './utils/technicalIndicators';

export default function CryptoDashboard() {
  const [darkMode, setDarkMode] = useState(true);
  const [cryptoData, setCryptoData] = useState([]);
  const [sentimentData, setSentimentData] = useState({});
  const [activeTab, setActiveTab] = useState('dashboard');
  const [user, setUser] = useState(null);
  const [alerts, setAlerts] = useState([]);
  const [portfolio, setPortfolio] = useState([]);

  useEffect(() => {
    fetchCryptoData();
    fetchSentimentData();
    checkUserAuthentication();
    fetchPriceAlerts();
    fetchUserPortfolio();
  }, []);

  const fetchCryptoData = async () => {
    try {
      const response = await axios.get('https://api.coingecko.com/api/v3/coins/markets', {
        params: {
          vs_currency: 'usd',
          order: 'market_cap_desc',
          per_page: 15,
          page: 1,
          sparkline: true
        }
      });
      setCryptoData(response.data);
    } catch (error) {
      console.error('Error fetching crypto data:', error);
    }
  };

  const fetchSentimentData = async () => {
    try {
      const response = await axios.get('/api/sentiment');
      setSentimentData(response.data);
    } catch (error) {
      console.error('Error fetching sentiment data:', error);
    }
  };

  const checkUserAuthentication = async () => {
    try {
      const response = await axios.get('/api/auth/user');
      setUser(response.data);
    } catch (error) {
      console.error('Error checking user authentication:', error);
    }
  };

  const fetchPriceAlerts = async () => {
    if (user) {
      try {
        const response = await axios.get('/api/alerts', { params: { userId: user.id } });
        setAlerts(response.data);
      } catch (error) {
        console.error('Error fetching price alerts:', error);
      }
    }
  };

  const fetchUserPortfolio = async () => {
    if (user) {
      try {
        const response = await axios.get('/api/portfolio', { params: { userId: user.id } });
        setPortfolio(response.data);
      } catch (error) {
        console.error('Error fetching user portfolio:', error);
      }
    }
  };

  const handleAddToPortfolio = async (coinId) => {
    if (user) {
      try {
        await axios.post('/api/portfolio', { userId: user.id, coinId });
        fetchUserPortfolio();
      } catch (error) {
        console.error('Error adding to portfolio:', error);
      }
    }
  };

  const calculatePortfolioValue = () => {
    return portfolio.reduce((total, item) => {
      const coin = cryptoData.find(c => c.id === item.coinId);
      return total + (coin ? coin.current_price * item.quantity : 0);
    }, 0);
  };

  return (
    <div className={`min-h-screen ${darkMode ? 'bg-gray-900 text-white' : 'bg-gray-100 text-gray-900'}`}> 
      <header className="flex justify-between items-center p-4">
        <h1 className="text-2xl font-bold">Crypto Market Dashboard</h1>
        <div className="flex items-center space-x-4">
          {user ? <span>Welcome, {user.name}</span> : <Button onClick={() => window.location.href='/login'}>Login</Button>}
          <Button onClick={() => setDarkMode(!darkMode)}>
            {darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
          </Button>
        </div>
      </header>

      <Tabs defaultValue="dashboard" value={activeTab} onValueChange={setActiveTab} className="p-4">
        <TabsList className="flex space-x-4">
          <TabsTrigger value="dashboard">Dashboard</TabsTrigger>
          <TabsTrigger value="trend-analysis">Trend Analysis</TabsTrigger>
          <TabsTrigger value="speculation">Speculation</TabsTrigger>
          <TabsTrigger value="portfolio">Portfolio</TabsTrigger>
        </TabsList>

        <TabsContent value="dashboard">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {cryptoData.map((coin) => {
              const rsi = calculateRSI(coin.sparkline_in_7d.price);
              const macd = calculateMACD(coin.sparkline_in_7d.price);
              const bollingerBands = calculateBollingerBands(coin.sparkline_in_7d.price);
              const fibonacci = calculateFibonacciRetracement(coin.sparkline_in_7d.price);
              const sentiment = sentimentData[coin.id]?.score || 'N/A';

              return (
                <Card key={coin.id} className="rounded-2xl shadow-lg">
                  <CardContent>
                    <div className="flex items-center justify-between">
                      <h2 className="text-xl font-semibold">{coin.name}</h2>
                      <img src={coin.image} alt={coin.name} className="w-8 h-8" />
                    </div>
                    <p className="mt-2 text-sm">Price: ${coin.current_price.toLocaleString()}</p>
                    <p className="text-sm">24h Change: <span className={coin.price_change_percentage_24h > 0 ? 'text-green-400' : 'text-red-400'}>
                      {coin.price_change_percentage_24h.toFixed(2)}%
                    </span></p>
                    <p className="text-sm">RSI: {rsi.toFixed(2)}</p>
                    <p className="text-sm">MACD: {macd.toFixed(2)}</p>
                    <p className="text-sm">Bollinger Bands: {bollingerBands.upper.toFixed(2)} / {bollingerBands.lower.toFixed(2)}</p>
                    <p className="text-sm">Fibonacci Levels: {fibonacci.join(', ')}</p>
                    <p className="text-sm">Sentiment Score: {sentiment}</p>
                    <Button className="mt-2 w-full" onClick={() => handleAddToPortfolio(coin.id)}>
                      <Wallet className="w-4 h-4 mr-2" /> Add to Portfolio
                    </Button>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </TabsContent>

        <TabsContent value="portfolio">
          <div className="p-4">
            <h2 className="text-2xl font-bold mb-4">Your Portfolio</h2>
            <p className="text-lg mb-4">Total Portfolio Value: ${calculatePortfolioValue().toFixed(2)}</p>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {portfolio.map((item) => {
                const coin = cryptoData.find(c => c.id === item.coinId);
                if (!coin) return null;
                return (
                  <Card key={item.coinId} className="rounded-2xl shadow-lg">
                    <CardContent>
                      <div className="flex items-center justify-between">
                        <h2 className="text-xl font-semibold">{coin.name}</h2>
                        <img src={coin.image} alt={coin.name} className="w-8 h-8" />
                      </div>
                      <p className="mt-2 text-sm">Quantity: {item.quantity}</p>
                      <p className="text-sm">Current Value: ${(coin.current_price * item.quantity).toFixed(2)}</p>
                      <p className="text-sm">Profit/Loss: ${((coin.current_price - item.purchase_price) * item.quantity).toFixed(2)}</p>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}
