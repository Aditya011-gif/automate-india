# Infura Setup Guide for AgriChain

## 🚀 Quick Start

### Step 1: Get Your Infura Credentials

1. **Visit Infura Dashboard**
   - Go to: https://infura.io/
   - Click "Get Started for Free" or "Sign Up"

2. **Create Account**
   - Sign up with your email
   - Verify your email address
   - Complete the onboarding process

3. **Create a New Project**
   - Click "Create New Key" or "Create New Project"
   - Choose "Web3 API" (Ethereum)
   - Project Name: `AgriChain Hackathon`
   - Network: Select `Ethereum` and `Polygon`

4. **Get Your Credentials**
   ```
   Project ID: abc123def456ghi789 (example)
   Project Secret: xyz789abc123def456 (optional, for enhanced security)
   ```

### Step 2: Configure Your Project

#### Option A: Direct Configuration (Quick Setup)

1. **Open the configuration file:**
   ```
   lib/config/app_config.dart
   ```

2. **Replace the placeholder values:**
   ```dart
   // Find these lines and replace YOUR_INFURA_PROJECT_ID
   static const String infuraProjectId = String.fromEnvironment('INFURA_PROJECT_ID',
     defaultValue: 'abc123def456ghi789'); // ← Put your Project ID here
   
   static const String infuraProjectSecret = String.fromEnvironment('INFURA_PROJECT_SECRET',
     defaultValue: 'xyz789abc123def456'); // ← Put your Project Secret here (optional)
   ```

#### Option B: Environment Variables (Recommended for Security)

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Edit the .env file:**
   ```bash
   # Open .env file and add your credentials
   INFURA_PROJECT_ID=abc123def456ghi789
   INFURA_PROJECT_SECRET=xyz789abc123def456
   ```

3. **Install flutter_dotenv package (if not already installed):**
   ```bash
   flutter pub add flutter_dotenv
   ```

### Step 3: Available Networks

Your AgriChain app now supports these networks via Infura:

#### Ethereum Networks:
- **Mainnet**: `https://mainnet.infura.io/v3/YOUR_PROJECT_ID`
- **Sepolia Testnet**: `https://sepolia.infura.io/v3/YOUR_PROJECT_ID`
- **Goerli Testnet**: `https://goerli.infura.io/v3/YOUR_PROJECT_ID`

#### Polygon Networks:
- **Polygon Mainnet**: `https://polygon-mainnet.infura.io/v3/YOUR_PROJECT_ID`
- **Mumbai Testnet**: `https://polygon-mumbai.infura.io/v3/YOUR_PROJECT_ID`

### Step 4: Test Your Configuration

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Check the blockchain service:**
   - The app will automatically use your Infura endpoints
   - Look for successful blockchain connections in the logs

## 🔧 Advanced Configuration

### Custom Network Selection

You can configure which network to use based on your environment:

```dart
// In your blockchain service
String getRpcUrl() {
  if (kDebugMode) {
    // Use testnet for development
    return AppConfig.ethereumSepoliaUrl; // or polygonMumbaiUrl
  } else {
    // Use mainnet for production
    return AppConfig.ethereumMainnetUrl; // or polygonMainnetUrl
  }
}
```

### Network Chain IDs

The configuration includes chain IDs for proper network identification:

```dart
static const int ethereumChainId = 1; // Mainnet
static const int polygonChainId = 137; // Polygon Mainnet
static const int sepoliaChainId = 11155111; // Sepolia Testnet
static const int mumbaiChainId = 80001; // Mumbai Testnet
```

### Rate Limiting

Infura has rate limits. For hackathons, the free tier provides:
- **100,000 requests per day**
- **10 requests per second**

This is usually sufficient for hackathon demos.

## 🛡️ Security Best Practices

### 1. Environment Variables
- ✅ **DO**: Use environment variables for production
- ❌ **DON'T**: Hardcode credentials in source code

### 2. Git Security
- ✅ **DO**: Add `.env` to `.gitignore`
- ❌ **DON'T**: Commit API keys to version control

### 3. Project Secrets
- ✅ **DO**: Use Project Secrets for enhanced security
- ❌ **DON'T**: Share credentials publicly

## 🚨 Troubleshooting

### Common Issues:

#### 1. "Invalid Project ID" Error
```
Solution: Double-check your Project ID in Infura dashboard
```

#### 2. "Rate Limit Exceeded" Error
```
Solution: 
- Check your usage in Infura dashboard
- Implement request caching
- Consider upgrading your Infura plan
```

#### 3. "Network Not Supported" Error
```
Solution: Ensure you've enabled the correct networks in your Infura project
```

#### 4. Connection Timeout
```
Solution: 
- Check your internet connection
- Verify Infura service status: https://status.infura.io/
- Increase timeout duration in AppConfig.blockchainTimeout
```

### Debug Mode

Enable debug logging to see network requests:

```dart
// In your blockchain service
if (kDebugMode) {
  print('Using RPC URL: ${AppConfig.ethereumRpcUrl}');
  print('Chain ID: ${AppConfig.ethereumChainId}');
}
```

## 📊 Monitoring Usage

### Infura Dashboard
- Monitor your API usage
- View request statistics
- Check error rates
- Upgrade plan if needed

### App Analytics
```dart
// Track blockchain interactions
void trackBlockchainCall(String method, bool success) {
  // Your analytics implementation
  print('Blockchain call: $method, Success: $success');
}
```

## 🎯 Hackathon Tips

### 1. Use Testnets
- Start with Sepolia (Ethereum) or Mumbai (Polygon)
- Free test tokens available from faucets
- No real money at risk

### 2. Mock Data Fallback
- Keep your mock blockchain service as backup
- Switch between real and mock based on configuration

### 3. Demo Preparation
- Test all blockchain features before demo
- Have backup plans for network issues
- Prepare test data and scenarios

### 4. Performance
- Cache blockchain responses when possible
- Use appropriate timeouts
- Handle network errors gracefully

## 📞 Support

### Infura Support:
- Documentation: https://docs.infura.io/
- Community: https://community.infura.io/
- Status Page: https://status.infura.io/

### AgriChain Support:
- Check the main README.md
- Review API_CREDENTIALS_GUIDE.md
- Contact your development team

---

## ✅ Quick Checklist

- [ ] Created Infura account
- [ ] Created new project with Ethereum + Polygon
- [ ] Copied Project ID and Secret
- [ ] Updated app_config.dart OR created .env file
- [ ] Added .env to .gitignore
- [ ] Tested blockchain connectivity
- [ ] Verified network selection works
- [ ] Prepared for hackathon demo

**🎉 You're ready to use Infura with AgriChain!**