import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class ChatbotService {
  static final VehicleService _vehicleService = VehicleService();
  static List<Vehicle> _cachedVehicles = [];
  static DateTime? _lastCacheUpdate;

  // ✅ NEW: Conversation context for more intelligent responses
  static final Map<String, dynamic> _conversationContext = {
    'previousQueries': <String>[],
    'userPreferences': <String, dynamic>{},
    'lastVehicleDiscussed': null,
    'conversationStage': 'greeting', // greeting, exploring, comparing, deciding
    'userBudget': null,
    'userType': null, // family, student, professional, etc.
  };

  // ✅ NEW: Enhanced personality traits
  static final List<String> _enthusiasticResponses = [
    "That's a fantastic choice! 🌟",
    "Great question! 🎯",
    "I love helping with that! 💪",
    "Excellent thinking! 🧠",
    "Perfect timing to ask! ⚡",
  ];

  static final List<String> _encouragingPhrases = [
    "You're on the right track!",
    "That's smart thinking!",
    "Good eye for details!",
    "I can see you're being thorough!",
    "That's exactly what I'd recommend checking!",
  ];

  // Process user message with enhanced intelligence
  static Future<String> processMessage(String userMessage) async {
    try {
      debugPrint('🤖 Processing: "$userMessage"');

      final message = userMessage.toLowerCase().trim();

      // Update conversation context
      _updateConversationContext(message);

      // Ensure we have vehicle data
      await _ensureVehicleData();

      // ✅ ENHANCED: More sophisticated message analysis
      final messageAnalysis = _analyzeMessageIntent(message);

      // Handle based on intent with context awareness
      switch (messageAnalysis['intent']) {
        case 'greeting':
          return _getContextualGreeting();
        case 'comparison':
          return await _handleEnhancedComparison(message, messageAnalysis);
        case 'price_query':
          return await _handleEnhancedPriceQuery(message, messageAnalysis);
        case 'recommendation':
          return await _handleEnhancedRecommendation(message, messageAnalysis);
        case 'specification':
          return await _handleEnhancedSpecQuery(message, messageAnalysis);
        case 'brand_inquiry':
          return await _handleEnhancedBrandQuery(message, messageAnalysis);
        case 'follow_up':
          return await _handleFollowUpQuestion(message, messageAnalysis);
        case 'clarification':
          return _handleClarificationRequest(message);
        case 'general_advice':
          return _handleGeneralAdvice(message, messageAnalysis);
        default:
          return _getContextualDefaultResponse();
      }
    } catch (e) {
      debugPrint('❌ Chatbot error: $e');
      return _getErrorResponse();
    }
  }

  // ✅ NEW: Advanced message intent analysis
  static Map<String, dynamic> _analyzeMessageIntent(String message) {
    final analysis = <String, dynamic>{
      'intent': 'unknown',
      'entities': <String>[],
      'confidence': 0.0,
      'context_clues': <String>[],
      'emotional_tone': 'neutral',
    };

    // Intent detection with confidence scoring
    final intentPatterns = {
      'greeting': [r'\b(hello|hi|hey|good\s+(morning|afternoon|evening))\b'],
      'comparison': [r'\b(compare|vs|versus|difference|better|which)\b'],
      'price_query': [r'\b(price|cost|expensive|cheap|budget|afford|\$)\b'],
      'recommendation': [
        r'\b(recommend|suggest|best|good|should|what\s+car)\b'
      ],
      'specification': [r'\b(mpg|mileage|fuel|electric|hybrid|engine|specs)\b'],
      'brand_inquiry': [
        r'\b(toyota|honda|ford|bmw|tesla|mercedes|audi|brand)\b'
      ],
      'follow_up': [r'\b(also|what\s+about|and|more|tell\s+me)\b'],
      'clarification': [
        r'\b(explain|what\s+do\s+you\s+mean|clarify|confused)\b'
      ],
      'general_advice': [r'\b(how\s+to|should\s+i|advice|help|guide)\b'],
    };

    double maxConfidence = 0.0;
    String bestIntent = 'unknown';

    for (final entry in intentPatterns.entries) {
      final intent = entry.key;
      final patterns = entry.value;

      double confidence = 0.0;
      for (final pattern in patterns) {
        final matches =
            RegExp(pattern, caseSensitive: false).allMatches(message);
        confidence += matches.length * 0.3;
      }

      if (confidence > maxConfidence) {
        maxConfidence = confidence;
        bestIntent = intent;
      }
    }

    analysis['intent'] = bestIntent;
    analysis['confidence'] = maxConfidence;

    // Extract entities (vehicle names, brands, numbers)
    analysis['entities'] = _extractEntities(message);

    // Detect emotional tone
    analysis['emotional_tone'] = _detectEmotionalTone(message);

    return analysis;
  }

  // ✅ NEW: Extract entities from message
  static List<String> _extractEntities(String message) {
    final entities = <String>[];

    // Extract potential vehicle names and brands
    for (final vehicle in _cachedVehicles) {
      if (message.contains(vehicle.name.toLowerCase())) {
        entities.add('vehicle:${vehicle.name}');
      }
      if (message.contains(vehicle.brand.toLowerCase())) {
        entities.add('brand:${vehicle.brand}');
      }
    }

    // Extract numbers (prices, mpg, etc.)
    final numberPattern = RegExp(r'\b\d+(?:,\d{3})*(?:\.\d+)?\b');
    final numbers = numberPattern.allMatches(message);
    for (final match in numbers) {
      entities.add('number:${match.group(0)}');
    }

    return entities;
  }

  // ✅ NEW: Detect emotional tone
  static String _detectEmotionalTone(String message) {
    final positiveWords = [
      'great',
      'awesome',
      'love',
      'perfect',
      'excellent',
      'amazing'
    ];
    final negativeWords = [
      'hate',
      'terrible',
      'awful',
      'bad',
      'disappointed',
      'confused'
    ];
    final urgentWords = ['urgent', 'asap', 'quickly', 'soon', 'immediately'];

    if (positiveWords.any((word) => message.contains(word))) return 'positive';
    if (negativeWords.any((word) => message.contains(word))) return 'negative';
    if (urgentWords.any((word) => message.contains(word))) return 'urgent';

    return 'neutral';
  }

  // ✅ NEW: Update conversation context
  static void _updateConversationContext(String message) {
    // Track conversation history
    _conversationContext['previousQueries'].add(message);
    if (_conversationContext['previousQueries'].length > 10) {
      _conversationContext['previousQueries'].removeAt(0);
    }

    // Extract and update user preferences
    if (message.contains('family')) {
      _conversationContext['userType'] = 'family';
      _conversationContext['userPreferences']['bodyType'] = 'SUV';
    }
    if (message.contains('student') || message.contains('college')) {
      _conversationContext['userType'] = 'student';
      _conversationContext['userPreferences']['budget'] = 'low';
    }
    if (message.contains('business') || message.contains('professional')) {
      _conversationContext['userType'] = 'professional';
      _conversationContext['userPreferences']['style'] = 'luxury';
    }

    // Extract budget information
    final budgetPattern = RegExp(r'\$?(\d+(?:,\d{3})*(?:k|000)?)\b');
    final budgetMatch = budgetPattern.firstMatch(message);
    if (budgetMatch != null) {
      String budgetStr = budgetMatch.group(1)!;
      if (budgetStr.endsWith('k')) {
        budgetStr = budgetStr.replaceAll('k', '000');
      }
      _conversationContext['userBudget'] =
          int.tryParse(budgetStr.replaceAll(',', ''));
    }
  }

  // ✅ ENHANCED: Contextual greeting
  static String _getContextualGreeting() {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final previousQueries = _conversationContext['previousQueries'] as List;

    if (previousQueries.isEmpty) {
      return """
$timeGreeting! I'm Alex, your personal OptiMoto assistant! 🚗✨

I'm here to make finding your perfect vehicle fun and easy! I can help you with:

🔍 **Smart Vehicle Search** - Tell me what you need
🆚 **Expert Comparisons** - Compare any vehicles side-by-side  
💰 **Budget Planning** - Find the best deals in your range
⚡ **Instant Specs** - Get detailed vehicle information
🎯 **Personal Recommendations** - Tailored just for you

What brings you here today? Are you:
• Looking for your first car?
• Upgrading your current vehicle?
• Shopping for your family?
• Just exploring options?

Just tell me what's on your mind! 😊
      """
          .trim();
    } else {
      final encouragement =
          _encouragingPhrases[Random().nextInt(_encouragingPhrases.length)];
      return """
Welcome back! $encouragement 

I remember we were chatting about vehicles. What would you like to explore next?

Quick options:
• Compare specific vehicles
• Get recommendations based on your needs
• Check pricing for vehicles you're interested in
• Learn about vehicle features and specs

What's your next question? 🚗
      """
          .trim();
    }
  }

  // ✅ ENHANCED: Intelligent comparison handling
  static List<Vehicle> _findSimilarVehicles(Vehicle vehicle) {
    return _cachedVehicles
        .where((v) =>
            v.type == vehicle.type &&
            (v.price - vehicle.price).abs() < 5000 &&
            v.id != vehicle.id)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
  }

  static Future<String> _handleEnhancedComparison(
      String message, Map<String, dynamic> analysis) async {
    try {
      final vehicles = _extractVehicleNames(message);
      final enthusiasm = _enthusiasticResponses[
          Random().nextInt(_enthusiasticResponses.length)];

      if (vehicles.length >= 2) {
        final vehicle1 = vehicles[0];
        final vehicle2 = vehicles[1];

        // Update context
        _conversationContext['lastVehicleDiscussed'] = [
          vehicle1.name,
          vehicle2.name
        ];
        _conversationContext['conversationStage'] = 'comparing';

        final winner = vehicle1.score > vehicle2.score ? vehicle1 : vehicle2;
        final valueLeader =
            vehicle1.price < vehicle2.price ? vehicle1 : vehicle2;
        final efficiencyLeader =
            vehicle1.mileage > vehicle2.mileage ? vehicle1 : vehicle2;

        return """
$enthusiasm Let me break down the **${vehicle1.name} vs ${vehicle2.name}** comparison for you:

## 📊 **Head-to-Head Comparison**

| Feature | **${vehicle1.name}** | **${vehicle2.name}** |
|---------|------------------|------------------|
| 💰 **Price** | \$${_formatPrice(vehicle1.price)} | \$${_formatPrice(vehicle2.price)} |
| ⛽ **Fuel Economy** | ${vehicle1.mileage} MPG | ${vehicle2.mileage} MPG |
| 🔧 **Fuel Type** | ${vehicle1.fuelType} | ${vehicle2.fuelType} |
| ⭐ **Overall Score** | ${(vehicle1.score * 100).toInt()}% | ${(vehicle2.score * 100).toInt()}% |

## 🏆 **The Verdict**
- **Overall Winner**: ${winner.name} (higher match score)
- **Best Value**: ${valueLeader.name} (lower price)
- **Most Efficient**: ${efficiencyLeader.name} (better MPG)

## 💡 **My Recommendation**
${_getIntelligentRecommendation(vehicle1, vehicle2)}

**Want to dive deeper?** I can tell you about:
        final competitors = _findSimilarVehicles(vehicle);
• Maintenance costs and reliability
• Resale value predictions
• Which one fits your specific needs better

What aspect interests you most? 🤔
        """
            .trim();
      } else if (vehicles.length == 1) {
        final vehicle = vehicles[0];
        final competitors = _findSimilarVehicles(vehicle).take(3).toList();

        if (competitors.isNotEmpty) {
          return """
Great choice looking at the **${vehicle.name}**! 🎯

Since you're interested in comparisons, here are the top competitors I'd recommend comparing it against:

${competitors.map((v) => "• **${v.name}** - \$${_formatPrice(v.price)} (${v.mileage} MPG)").join('\n')}

Which of these would you like me to compare with the ${vehicle.name}? Or would you prefer to:
• See detailed specs for the ${vehicle.name}
• Find vehicles in a similar price range
• Get my recommendation based on your needs

Just let me know! 😊
          """
              .trim();
        }
      }

      return """
I'd love to help you compare vehicles! 🔍

To give you the most accurate comparison, could you tell me which specific vehicles you're considering? For example:
• "Compare Toyota Camry vs Honda Accord"
• "Tesla Model 3 vs BMW 3 Series"
• "Best SUV under \$40,000"

Or if you're not sure what to compare, I can recommend vehicles based on:
• Your budget range
• Your primary use (family, commuting, etc.)
• Your preferred features (fuel efficiency, luxury, etc.)

What would be most helpful for you? 🤔
      """
          .trim();
    } catch (e) {
      return "I'm excited to help you compare vehicles! Could you specify which cars you'd like me to compare?";
    }
  }

  // ✅ ENHANCED: Intelligent price handling
  static Future<String> _handleEnhancedPriceQuery(
      String message, Map<String, dynamic> analysis) async {
    try {
      final vehicles = _extractVehicleNames(message);
      final entities = analysis['entities'] as List<String>;
      final userBudget = _conversationContext['userBudget'];

      if (vehicles.isNotEmpty) {
        final vehicle = vehicles[0];
        final monthlyPayment = _calculateMonthlyPayment(vehicle.price);
        final alternatives = _findPriceAlternatives(vehicle);

        return """
💰 **${vehicle.name} Pricing Breakdown**

**Current Price**: \$${_formatPrice(vehicle.price)} ${_getPriceAnalysis(vehicle.price)}
**Monthly Payment**: ~\$${monthlyPayment}/month (60-month loan, 6% APR)
**Price Category**: ${_getPriceCategory(vehicle.price)}

## 📈 **Market Context**
${_getMarketContext(vehicle)}

## 💡 **Smart Alternatives**
${alternatives.map((v) => "• **${v.name}** - \$${_formatPrice(v.price)} (Save \$${_formatPrice(vehicle.price - v.price)})").join('\n')}

${userBudget != null ? _getBudgetAdvice(vehicle.price, userBudget) : _getGeneralBudgetAdvice()}

**Ready to move forward?** I can help you:
• Find financing options
• Calculate total ownership costs
• Negotiate better deals
• Explore certified pre-owned options

What's your next step? 🚗
        """
            .trim();
      }

      // Handle budget-specific queries
      final budgetNumbers =
          entities.where((e) => e.startsWith('number:')).toList();
      if (budgetNumbers.isNotEmpty || message.contains('budget')) {
        return await _handleBudgetQuery(message, budgetNumbers);
      }

      return _getGeneralPricingGuidance();
    } catch (e) {
      return "I'd be happy to help with pricing! Which vehicle are you curious about?";
    }
  }

  // ✅ NEW: Default response for unknown intents
  static String _getContextualDefaultResponse() {
    return """
  I'm sorry, I didn't quite understand that. 🤔
  
  Here are some things I can help you with:
  • Vehicle recommendations based on your needs
  • Comparing two or more vehicles
  • Pricing and budget-friendly options
  • Detailed specifications of any vehicle
  • General advice on car buying
  
  Could you rephrase your question or provide more details? 😊
      """
        .trim();
  }

  // ✅ ENHANCED: Intelligent recommendations
  static Future<String> _handleEnhancedRecommendation(
      String message, Map<String, dynamic> analysis) async {
    try {
      final preferences = _analyzeEnhancedPreferences(message);
      final userType = _conversationContext['userType'];
      final emotionalTone = analysis['emotional_tone'];

      // Merge with stored preferences
      final storedPrefs =
          _conversationContext['userPreferences'] as Map<String, dynamic>;
      preferences.addAll(storedPrefs);

      final recommended = _getIntelligentRecommendations(preferences);

      if (recommended.isNotEmpty) {
        final enthusiasm = emotionalTone == 'positive'
            ? "I'm excited to help you find the perfect match! ✨"
            : "Let me find some great options for you! 🎯";

        String response =
            "$enthusiasm\n\n## 🎯 **Perfect Matches for You**\n\n";

        for (int i = 0; i < recommended.take(3).length; i++) {
          final vehicle = recommended[i];
          final reasons =
              _getDetailedRecommendationReasons(vehicle, preferences);
          final personalizedNote = _getPersonalizedNote(vehicle, userType);

          response += """
### ${i + 1}. **${vehicle.name}** by ${vehicle.brand}
💰 **\$${_formatPrice(vehicle.price)}** | ⛽ **${vehicle.mileage} MPG** | 🔧 **${vehicle.fuelType}**

**Why it's perfect for you:**
${reasons}

$personalizedNote

---
          """;
        }

        response += """
**Need more options?** I can also:
• Adjust recommendations based on specific features
• Show you vehicles just outside your criteria
• Compare these top picks side-by-side
• Help you prioritize your must-haves vs nice-to-haves

What catches your eye? 👀
        """
            .trim();

        return response;
      }

      return _getNoRecommendationsGuidance(preferences);
    } catch (e) {
      return "I'd love to recommend the perfect vehicle! Tell me what you're looking for.";
    }
  }

  // ✅ NEW: Helper methods for enhanced responses
  static String _formatPrice(double price) {
    if (price >= 1000000) {
      return "${(price / 1000000).toStringAsFixed(1)}M";
    } else if (price >= 1000) {
      return "${(price / 1000).toStringAsFixed(0)}K";
    }
    return price.toStringAsFixed(0);
  }

  static String _getPriceAnalysis(double price) {
    if (price < 20000) return "🟢 Great value!";
    if (price < 35000) return "🟡 Fair price";
    if (price < 50000) return "🟠 Premium range";
    return "🔴 Luxury territory";
  }

  static String _getPriceCategory(double price) {
    if (price < 20000) return "Budget-Friendly";
    if (price < 35000) return "Mid-Range";
    if (price < 50000) return "Premium";
    return "Luxury";
  }

  static int _calculateMonthlyPayment(double price,
      {double downPayment = 0.1, int months = 60, double apr = 0.06}) {
    final loanAmount = price * (1 - downPayment);
    final monthlyRate = apr / 12;
    final payment = loanAmount *
        (monthlyRate * pow(1 + monthlyRate, months)) /
        (pow(1 + monthlyRate, months) - 1);
    return payment.round();
  }

  static String _getMarketContext(Vehicle vehicle) {
    final similar = _cachedVehicles
        .where((v) =>
            v.type == vehicle.type &&
            (v.price - vehicle.price).abs() < 5000 &&
            v.id != vehicle.id)
        .toList();

    if (similar.isNotEmpty) {
      final avgPrice =
          similar.map((v) => v.price).reduce((a, b) => a + b) / similar.length;
      final comparison = vehicle.price < avgPrice
          ? "📉 Below average for its class (good deal!)"
          : "📈 Above average for its class";
      return comparison;
    }
    return "📊 Competitive pricing in its segment";
  }

  static List<Vehicle> _findPriceAlternatives(Vehicle vehicle) {
    return _cachedVehicles
        .where((v) =>
            v.type == vehicle.type &&
            v.price < vehicle.price &&
            v.id != vehicle.id)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score))
      ..take(2).toList();
  }

  static String _getBudgetAdvice(double vehiclePrice, int budget) {
    if (vehiclePrice <= budget) {
      return "✅ **Great news!** This fits perfectly within your \$${_formatPrice(budget.toDouble())} budget!";
    } else {
      final over = vehiclePrice - budget;
      return "⚠️ **Heads up:** This is \$${_formatPrice(over)} over your \$${_formatPrice(budget.toDouble())} budget. Consider alternatives or financing options.";
    }
  }

  static String _getGeneralBudgetAdvice() {
    return "💡 **Pro tip:** Factor in insurance, maintenance, and fuel costs when budgeting!";
  }

  static String _getIntelligentRecommendation(Vehicle v1, Vehicle v2) {
    if (v1.price < v2.price && v1.mileage > v2.mileage) {
      return "${v1.name} offers better value with lower price and better fuel economy.";
    }
    if (v2.price < v1.price && v2.mileage > v1.mileage) {
      return "${v2.name} offers better value with lower price and better fuel economy.";
    }
    if (v1.score > v2.score) {
      return "${v1.name} has a higher overall match score for most users.";
    }
    return "${v2.name} has a higher overall match score for most users.";
  }

  static Map<String, dynamic> _analyzeEnhancedPreferences(String message) {
    final preferences = <String, dynamic>{};

    // Budget analysis
    if (message.contains('budget') ||
        message.contains('cheap') ||
        message.contains('affordable')) {
      preferences['maxPrice'] = 25000;
    }
    if (message.contains('luxury') || message.contains('premium')) {
      preferences['minPrice'] = 50000;
    }

    // Type analysis
    if (message.contains('suv')) preferences['type'] = 'SUV';
    if (message.contains('sedan')) preferences['type'] = 'Sedan';
    if (message.contains('truck')) preferences['type'] = 'Pickup Truck';

    // Fuel analysis
    if (message.contains('electric')) preferences['fuelType'] = 'Electric';
    if (message.contains('hybrid')) preferences['fuelType'] = 'Hybrid';
    if (message.contains('fuel efficient') || message.contains('mpg')) {
      preferences['minMileage'] = 30;
    }

    // Family/size analysis
    if (message.contains('family') || message.contains('kids')) {
      preferences['type'] = 'SUV';
      preferences['familyFriendly'] = true;
    }

    return preferences;
  }

  static List<Vehicle> _getIntelligentRecommendations(
      Map<String, dynamic> preferences) {
    var filtered = _cachedVehicles.where((vehicle) {
      // Price filtering
      if (preferences['maxPrice'] != null &&
          vehicle.price > preferences['maxPrice']) {
        return false;
      }
      if (preferences['minPrice'] != null &&
          vehicle.price < preferences['minPrice']) {
        return false;
      }

      // Type filtering
      if (preferences['type'] != null && vehicle.type != preferences['type']) {
        return false;
      }

      // Fuel type filtering
      if (preferences['fuelType'] != null &&
          vehicle.fuelType != preferences['fuelType']) {
        return false;
      }

      // Mileage filtering
      if (preferences['minMileage'] != null &&
          vehicle.mileage < preferences['minMileage']) {
        return false;
      }

      return true;
    }).toList();

    // Sort by score
    filtered.sort((a, b) => b.score.compareTo(a.score));
    return filtered.take(5).toList();
  }

  static String _getDetailedRecommendationReasons(
      Vehicle vehicle, Map<String, dynamic> preferences) {
    final reasons = <String>[];

    if (vehicle.mileage > 30)
      reasons.add("• Excellent fuel economy (${vehicle.mileage} MPG)");
    if (vehicle.price < 30000) reasons.add("• Great value under \$30K");
    if (vehicle.fuelType == 'Electric')
      reasons.add("• Zero emissions & low operating costs");
    if (vehicle.fuelType == 'Hybrid')
      reasons.add("• Eco-friendly hybrid technology");
    if (vehicle.score > 0.9)
      reasons
          .add("• High reliability rating (${(vehicle.score * 100).toInt()}%)");
    if (vehicle.type == 'SUV') reasons.add("• Spacious and practical");

    if (reasons.isEmpty) reasons.add("• Well-balanced features for most users");

    return reasons.join('\n');
  }

  static String _getPersonalizedNote(Vehicle vehicle, String? userType) {
    switch (userType) {
      case 'family':
        return "👨‍👩‍👧‍👦 **Family-friendly features:** Spacious interior, excellent safety ratings, easy loading";
      case 'student':
        return "🎓 **Perfect for students:** Affordable, reliable, good fuel economy for campus life";
      case 'professional':
        return "💼 **Professional choice:** Reliable commuter with professional appearance";
      default:
        return "✨ **Special note:** Great choice that balances performance, efficiency, and value!";
    }
  }

  static String _getNoRecommendationsGuidance(
      Map<String, dynamic> preferences) {
    return """
I'd love to help you find the perfect vehicle! 🎯

It looks like your criteria might be very specific. Let me help by:
• Expanding the search to nearby options
• Suggesting similar alternatives
• Helping you prioritize your must-haves vs nice-to-haves

What's most important to you: price, fuel efficiency, size, brand, or something else?
    """
        .trim();
  }

  static Future<String> _handleBudgetQuery(
      String message, List<String> budgetNumbers) async {
    try {
      // Extract budget from numbers or text
      int? budget;

      if (budgetNumbers.isNotEmpty) {
        final numberStr =
            budgetNumbers.first.replaceAll('number:', '').replaceAll(',', '');
        budget = int.tryParse(numberStr);
      }

      // Look for budget keywords
      if (budget == null) {
        if (message.contains('budget') && message.contains('20'))
          budget = 20000;
        if (message.contains('budget') && message.contains('30'))
          budget = 30000;
        if (message.contains('under') && message.contains('25')) budget = 25000;
      }

      budget ??= 30000; // Default budget

      final affordable = _cachedVehicles
          .where((v) => v.price <= budget!)
          .toList()
        ..sort((a, b) => a.price.compareTo(b.price));

      if (affordable.isNotEmpty) {
        String response =
            "💰 **Great Options Under \$${_formatPrice(budget.toDouble())}:**\n\n";

        for (int i = 0; i < affordable.take(5).length; i++) {
          final v = affordable[i];
          final monthlyPayment = _calculateMonthlyPayment(v.price);
          response += """
**${i + 1}. ${v.name}** (${v.brand})
💰 \$${_formatPrice(v.price)} (~\$${monthlyPayment}/month)
⛽ ${v.mileage} MPG | 🔧 ${v.fuelType}

          """;
        }

        response +=
            "💡 **Tip:** Consider certified pre-owned options for even better value!\n\nWant details on any of these?";
        return response.trim();
      }

      return "I couldn't find vehicles in that exact budget range. Would you like me to:\n• Show options slightly above your budget\n• Look at certified pre-owned vehicles\n• Suggest financing options";
    } catch (e) {
      return "I'd be happy to help with budget-friendly options! What's your target price range?";
    }
  }

  static String _getGeneralPricingGuidance() {
    return """
💰 **Vehicle Pricing Help**

I can help you understand:
• **Market pricing** for specific vehicles
• **Budget-friendly options** in your range
• **Monthly payment estimates**
• **Total cost of ownership**

What would you like to know? Try asking:
• "What's a good car under \$25,000?"
• "Tesla Model 3 price"
• "Monthly payment for Honda Accord"
    """
        .trim();
  }

  static Future<String> _handleEnhancedSpecQuery(
      String message, Map<String, dynamic> analysis) async {
    try {
      final vehicles = _extractVehicleNames(message);

      if (vehicles.isNotEmpty) {
        final vehicle = vehicles[0];

        if (message.contains('mpg') ||
            message.contains('mileage') ||
            message.contains('fuel')) {
          final comparison = _getFuelEconomyComparison(vehicle);
          return """
⛽ **${vehicle.name} Fuel Economy**

**MPG:** ${vehicle.mileage}
**Fuel Type:** ${vehicle.fuelType}
**Annual Fuel Cost:** ~\$${_calculateAnnualFuelCost(vehicle)}

$comparison

💡 **Fuel Efficiency Tip:** ${_getFuelTip(vehicle)}

Want to compare with other vehicles or learn about ${vehicle.fuelType} technology?
          """
              .trim();
        }

        if (message.contains('electric') || message.contains('hybrid')) {
          return _getElectricInfo(vehicle);
        }

        // General specs
        return """
📋 **${vehicle.name} Complete Specifications**

**Basic Info:**
• Brand: ${vehicle.brand}
• Type: ${vehicle.type}
• Price: \$${_formatPrice(vehicle.price)}

**Performance:**
• Fuel Economy: ${vehicle.mileage} MPG
• Fuel Type: ${vehicle.fuelType}

**OptiMoto Score:** ${(vehicle.score * 100).toInt()}% match

**Want more details?** Ask about:
• Safety features • Maintenance costs • Resale value • Similar alternatives
        """
            .trim();
      }

      return "I can provide detailed specifications! Which vehicle would you like to know about? Try asking about specific features like 'Honda Civic MPG' or 'Tesla Model 3 specs'.";
    } catch (e) {
      return "I'd be happy to share vehicle specifications. Which car interests you?";
    }
  }

  static Future<String> _handleEnhancedBrandQuery(
      String message, Map<String, dynamic> analysis) async {
    try {
      // Extract brand from message
      final brands = [
        'toyota',
        'honda',
        'ford',
        'chevrolet',
        'bmw',
        'tesla',
        'mercedes',
        'audi'
      ];
      final mentionedBrand = brands.firstWhere(
        (brand) => message.contains(brand),
        orElse: () => '',
      );

      if (mentionedBrand.isNotEmpty) {
        final brandVehicles = _cachedVehicles
            .where((v) => v.brand.toLowerCase() == mentionedBrand)
            .toList()
          ..sort((a, b) => b.score.compareTo(a.score));

        if (brandVehicles.isNotEmpty) {
          String response =
              "🏭 **${mentionedBrand.toUpperCase()} Vehicle Lineup:**\n\n";

          for (int i = 0; i < brandVehicles.take(5).length; i++) {
            final v = brandVehicles[i];
            response += """
**${i + 1}. ${v.name}**
💰 \$${_formatPrice(v.price)} | ⛽ ${v.mileage} MPG | 📊 ${(v.score * 100).toInt()}%

            """;
          }

          response += "\n${_getBrandInsight(mentionedBrand)}\n\n";
          response +=
              "Want to know more about any specific ${mentionedBrand} model or compare with other brands?";
          return response.trim();
        }
      }

      return "I can help you explore different car brands! Which brand interests you?\n\n**Popular brands I know about:**\n• Toyota • Honda • Tesla • BMW • Ford • Mercedes • Audi • Chevrolet\n\nJust ask about any brand!";
    } catch (e) {
      return "I'd be happy to help you learn about different car brands. Which one interests you?";
    }
  }

  static Future<String> _handleFollowUpQuestion(
      String message, Map<String, dynamic> analysis) async {
    final previousQueries = _conversationContext['previousQueries'] as List;
    final lastVehicle = _conversationContext['lastVehicleDiscussed'];

    if (lastVehicle != null && lastVehicle is List && lastVehicle.isNotEmpty) {
      final vehicleName = lastVehicle.first;
      return """
Great follow-up question! 🎯

Since we were talking about the **$vehicleName**, here are some related things you might want to know:

• **Maintenance costs** and reliability
• **Insurance rates** for this model
• **Resale value** trends
• **Similar alternatives** to consider
• **Owner reviews** and experiences

What specific aspect interests you most?
      """
          .trim();
    }

    if (previousQueries.isNotEmpty) {
      final lastQuery = previousQueries.last;
      return """
I see you want to know more! 🤔

Based on our conversation about "$lastQuery", I can help with:
• More detailed information
• Related recommendations
• Comparisons with alternatives
• Next steps in your decision process

What would be most helpful?
      """
          .trim();
    }

    return "I'd love to help you explore further! What additional information can I provide?";
  }

  static String _handleClarificationRequest(String message) {
    return """
Of course! Let me clarify that for you. 😊

I'm here to help make car shopping easier by providing:
• **Vehicle information** - specs, pricing, features
• **Comparisons** - side-by-side analysis of different cars
• **Recommendations** - personalized suggestions based on your needs
• **Market insights** - pricing trends and value analysis

What specific part would you like me to explain better? Or ask me something like:
• "Explain the difference between hybrid and electric"
• "What should I look for in a family car?"
• "How do I know if I'm getting a good deal?"
    """
        .trim();
  }

  static String _handleGeneralAdvice(
      String message, Map<String, dynamic> analysis) {
    if (message.contains('how') &&
        (message.contains('choose') || message.contains('pick'))) {
      return """
🤔 **How to Choose the Right Vehicle - My Expert Guide:**

**1. Define Your Needs**
• Primary use (commuting, family, recreation)
• Passenger and cargo requirements
• Driving conditions (city, highway, off-road)

**2. Set Your Budget**
• Purchase price + taxes + fees
• Insurance costs (get quotes first!)
• Fuel and maintenance expenses
• Financing vs. cash considerations

**3. Research & Compare**
• Safety ratings (NHTSA, IIHS)
• Reliability history and reviews
• Resale value predictions
• Owner satisfaction scores

**4. Smart Shopping**
• Get pre-approved for financing
• Shop multiple dealers/sellers
• Inspect thoroughly (or get professional inspection)
• Negotiate total price, not monthly payments

**5. Final Decision**
• Test drive in various conditions
• Compare final offers
• Read all paperwork carefully
• Trust your instincts!

💡 **I can help with any of these steps!** What stage are you at in your car buying journey?
      """
          .trim();
    }

    if (message.contains('maintain') || message.contains('care')) {
      return """
🔧 **Vehicle Care & Maintenance Advice:**

**Essential Maintenance:**
• Oil changes every 5,000-7,500 miles
• Tire rotation every 6,000-8,000 miles
• Brake inspections annually
• Air filter replacement as needed

**Seasonal Care:**
• Winter: Check battery, tires, fluids
• Summer: AC service, cooling system check
• Year-round: Keep it clean inside and out

**Cost-Saving Tips:**
• Follow manufacturer's schedule (not dealer's "recommendations")
• Learn basic maintenance (air filters, etc.)
• Find a trusted independent mechanic
• Keep maintenance records for resale value

Want specific advice for a particular vehicle or maintenance topic?
      """
          .trim();
    }

    return """
I'm full of automotive advice! 🚗💡

**Popular topics I can help with:**
• Choosing the right vehicle for your needs
• Understanding financing and leasing
• Maintenance and care tips
• Negotiating and buying strategies
• Electric vs. gas vs. hybrid decisions
• Safety and reliability insights

What automotive topic can I help you with today?
    """
        .trim();
  }

  // ✅ ADD: Missing utility methods
  static String _getFuelEconomyComparison(Vehicle vehicle) {
    if (_cachedVehicles.isEmpty)
      return "**Comparison:** Data not available currently.";

    final average =
        _cachedVehicles.map((v) => v.mileage).reduce((a, b) => a + b) /
            _cachedVehicles.length;

    if (vehicle.mileage > average + 5) {
      return "**Comparison:** Excellent! ${(vehicle.mileage - average).toInt()} MPG above average (${average.toInt()} MPG).";
    } else if (vehicle.mileage > average) {
      return "**Comparison:** Good! Above average fuel economy (average: ${average.toInt()} MPG).";
    } else {
      return "**Comparison:** Below average fuel economy, but may offer other benefits like performance or space.";
    }
  }

  static int _calculateAnnualFuelCost(Vehicle vehicle) {
    // Assume 12,000 miles/year, $3.50/gallon for gas, $0.12/kWh for electric
    if (vehicle.fuelType == 'Electric') {
      // Convert MPG equivalent to actual cost
      final kWhPer100Miles = 100 / (vehicle.mileage / 3.3); // Rough conversion
      return ((12000 / 100) * kWhPer100Miles * 0.12).round();
    } else {
      final gallonsPerYear = 12000 / vehicle.mileage;
      return (gallonsPerYear * 3.50).round();
    }
  }

  static String _getFuelTip(Vehicle vehicle) {
    if (vehicle.fuelType == 'Electric') {
      return "Electric vehicles can save \$1000+ annually on fuel costs and require minimal maintenance!";
    }
    if (vehicle.fuelType == 'Hybrid') {
      return "Hybrids offer the best of both worlds - great fuel economy with gas convenience.";
    }
    if (vehicle.mileage > 35) {
      return "Excellent fuel economy will save you significant money at the pump!";
    }
    return "Consider hybrid or electric options for better fuel efficiency and lower operating costs.";
  }

  static String _getElectricInfo(Vehicle vehicle) {
    if (vehicle.fuelType == 'Electric') {
      return """
⚡ **${vehicle.name} - Electric Vehicle Details**

**Range:** ~${vehicle.mileage * 3} miles (EPA equivalent)
**Charging Time:** 
• Level 1 (120V): 8-20 hours
• Level 2 (240V): 3-8 hours  
• DC Fast: 20-45 minutes to 80%

**Annual Energy Cost:** ~\$${_calculateAnnualFuelCost(vehicle)}
**Emissions:** Zero direct emissions

**EV Benefits:**
• Lower maintenance (no oil changes!)
• Instant torque & quiet operation
• HOV lane access in many areas
• Potential tax incentives

💡 **Charging tip:** Most EV owners charge at home overnight for daily driving.
      """
          .trim();
    } else if (vehicle.fuelType == 'Hybrid') {
      return """
🔋 **${vehicle.name} - Hybrid Vehicle Details**

**Combined MPG:** ${vehicle.mileage}
**Technology:** Gas engine + electric motor working together
**Annual Fuel Cost:** ~\$${_calculateAnnualFuelCost(vehicle)}

**Hybrid Benefits:**
• Better fuel economy than gas-only
• No range anxiety (gas backup)
• Lower emissions
• Often qualify for HOV lanes

💡 **How it works:** The electric motor assists the gas engine for better efficiency and can power the car at low speeds.
      """
          .trim();
    } else {
      return """
⛽ **${vehicle.name} - Traditional Gas Engine**

**MPG:** ${vehicle.mileage}
**Annual Fuel Cost:** ~\$${_calculateAnnualFuelCost(vehicle)}

**Gas Engine Benefits:**
• Familiar technology
• Wide refueling network
• Generally lower purchase price
• Quick refueling

💡 **Consider upgrading:** Our hybrid and electric options offer better efficiency and lower operating costs!

Want to see hybrid or electric alternatives to the ${vehicle.name}?
      """
          .trim();
    }
  }

  static String _getBrandInsight(String brand) {
    switch (brand.toLowerCase()) {
      case 'toyota':
        return "💡 **Toyota:** World leader in reliability and fuel efficiency. Known for strong resale value and hybrid technology leadership.";
      case 'honda':
        return "💡 **Honda:** Reputation for dependability and practical engineering. Excellent build quality and low maintenance costs.";
      case 'tesla':
        return "💡 **Tesla:** Electric vehicle pioneer with cutting-edge technology, Autopilot features, and impressive performance.";
      case 'bmw':
        return "💡 **BMW:** Premium German engineering focused on 'Ultimate Driving Machine' performance and luxury features.";
      case 'ford':
        return "💡 **Ford:** American heritage with strong truck lineup. Innovation leader with electric F-150 and Mustang Mach-E.";
      case 'mercedes':
        return "💡 **Mercedes-Benz:** Luxury and safety innovation leader. Often introduces features that become industry standards.";
      case 'audi':
        return "💡 **Audi:** Quattro all-wheel drive specialists with sophisticated technology and sleek design.";
      case 'chevrolet':
        return "💡 **Chevrolet:** Wide range from affordable to performance vehicles. Strong presence in trucks and electric (Bolt).";
      default:
        return "💡 Each brand has unique strengths and characteristics. Would you like specific comparisons between brands?";
    }
  }

  // ✅ ENHANCED: More sophisticated error responses
  static String _getErrorResponse() {
    final responses = [
      "Oops! I hit a small snag. 🤖 Let me try that again - what can I help you with?",
      "Sorry about that! Even AI assistants have off moments. 😅 What were you asking about?",
      "Hmm, something went sideways there. Let's get back on track - how can I assist you today?",
    ];
    return responses[Random().nextInt(responses.length)];
  }

  // ✅ ADD: Extract vehicle names from message
  static List<Vehicle> _extractVehicleNames(String message) {
    final found = <Vehicle>[];

    for (final vehicle in _cachedVehicles) {
      final vehicleName = vehicle.name.toLowerCase();
      final brandName = vehicle.brand.toLowerCase();

      // Check if message contains vehicle name or brand + model
      if (message.contains(vehicleName) ||
          (message.contains(brandName) &&
              vehicleName.contains(message.split(' ').last))) {
        found.add(vehicle);
      }
    }

    return found;
  }

  static Future<void> _ensureVehicleData() async {
    final now = DateTime.now();

    // Cache for 5 minutes
    if (_cachedVehicles.isEmpty ||
        _lastCacheUpdate == null ||
        now.difference(_lastCacheUpdate!).inMinutes > 5) {
      try {
        debugPrint('🔄 Fetching fresh vehicle data...');
        _cachedVehicles = await _vehicleService.getVehicles();
        _lastCacheUpdate = now;
        debugPrint('✅ Cached ${_cachedVehicles.length} vehicles');
      } catch (e) {
        debugPrint('⚠️ Failed to fetch vehicles, using sample data');
        _cachedVehicles = _getSampleVehicles();
        _lastCacheUpdate = now;
      }
    }
  }

  static List<Vehicle> _getSampleVehicles() {
    return [
      Vehicle(
          id: '1',
          name: 'Toyota Camry',
          brand: 'Toyota',
          price: 28000,
          type: 'Sedan',
          mileage: 32,
          fuelType: 'Gasoline',
          score: 0.88,
          imageUrl: ''),
      Vehicle(
          id: '2',
          name: 'Honda Accord',
          brand: 'Honda',
          price: 26000,
          type: 'Sedan',
          mileage: 33,
          fuelType: 'Gasoline',
          score: 0.86,
          imageUrl: ''),
      Vehicle(
          id: '3',
          name: 'Tesla Model 3',
          brand: 'Tesla',
          price: 45000,
          type: 'Sedan',
          mileage: 120,
          fuelType: 'Electric',
          score: 0.95,
          imageUrl: ''),
      Vehicle(
          id: '4',
          name: 'Toyota RAV4',
          brand: 'Toyota',
          price: 32000,
          type: 'SUV',
          mileage: 30,
          fuelType: 'Gasoline',
          score: 0.87,
          imageUrl: ''),
      Vehicle(
          id: '5',
          name: 'Honda CR-V',
          brand: 'Honda',
          price: 31000,
          type: 'SUV',
          mileage: 29,
          fuelType: 'Gasoline',
          score: 0.85,
          imageUrl: ''),
    ];
  }
}
