import '../models/guide.dart';

class GuidesService {
  // Sample guides data with creative automotive content
  static final List<Guide> _sampleGuides = [
    Guide(
      id: '1',
      title: 'First-Time Car Buyer\'s Complete Guide',
      subtitle: 'Everything you need to know before buying your first vehicle',
      description:
          'A comprehensive guide covering budgeting, financing, insurance, and what to look for when buying your first car.',
      content: '''
# First-Time Car Buyer's Complete Guide

## Setting Your Budget
Before you start looking at cars, it's crucial to determine what you can afford. A good rule of thumb is to spend no more than 10-15% of your take-home pay on a car payment.

### Consider These Costs:
- Down payment (typically 10-20%)
- Monthly payments
- Insurance (get quotes before buying)
- Maintenance and repairs
- Fuel costs
- Registration and taxes

## New vs. Used Cars

### New Cars Advantages:
- Latest safety features and technology
- Full warranty coverage
- Better financing rates
- No hidden problems

### Used Cars Advantages:
- Lower purchase price
- Slower depreciation
- Lower insurance costs
- More car for your money

## Financing Options

### Dealership Financing
Convenient but may not offer the best rates.

### Bank/Credit Union Loans
Often better rates, get pre-approved for negotiating power.

### Leasing
Lower monthly payments but no ownership.

## What to Inspect Before Buying

### Exterior:
- Check for rust, dents, scratches
- Tire condition and wear patterns
- Paint consistency

### Interior:
- Seat wear and functionality
- Electronics and controls
- Air conditioning and heating

### Under the Hood:
- Fluid levels and colors
- Belt condition
- Battery age

### Test Drive Checklist:
- Smooth starting
- Transmission shifts
- Braking performance
- Steering responsiveness
- No unusual noises

## Final Tips
- Research the car's history (Carfax/AutoCheck)
- Get a pre-purchase inspection
- Negotiate the total price, not monthly payments
- Don't rush the decision
- Have all paperwork reviewed before signing
      ''',
      category: 'Buying Guide',
      tags: ['first-time buyer', 'budgeting', 'financing', 'inspection'],
      imageUrl: 'https://example.com/first-car-guide.jpg',
      author: 'Sarah Mitchell',
      publishedDate: DateTime.now().subtract(const Duration(days: 5)),
      readTime: 12,
      rating: 4.8,
      views: 2341,
      isFeatured: true,
    ),
    Guide(
      id: '2',
      title: 'Electric Vehicle Charging: A Complete Guide',
      subtitle: 'Master EV charging at home and on the road',
      description:
          'Learn everything about electric vehicle charging, from home installation to public charging networks.',
      content: '''
# Electric Vehicle Charging: A Complete Guide

## Types of EV Charging

### Level 1 Charging (120V)
- Speed: 2-5 miles of range per hour
- Best for: Overnight charging at home
- Equipment: Standard household outlet
- Time: 8-20 hours for full charge

### Level 2 Charging (240V)
- Speed: 10-60 miles of range per hour
- Best for: Home, workplace, public charging
- Equipment: Special charging station required
- Time: 3-8 hours for full charge

### DC Fast Charging (Level 3)
- Speed: 60-200+ miles of range in 20-30 minutes
- Best for: Long trips, quick top-ups
- Equipment: Commercial charging stations
- Time: 20-45 minutes for 80% charge

## Home Charging Setup

### Installation Considerations:
- Electrical panel capacity
- Distance from panel to charging location
- Permits and inspections required
- Professional electrician recommended

### Cost Factors:
- Charging station: 500-2,000 USD
- Installation: 500-2,000 USD
- Electrical upgrades if needed: 1,000-5,000 USD

## Public Charging Networks

### Major Networks:
- Tesla Supercharger: Fastest, Tesla-exclusive (opening to others)
- Electrify America: Nationwide, high-speed charging
- ChargePoint: Largest network, various speeds
- EVgo: Fast charging focus

### Finding Charging Stations:
- PlugShare app
- ChargeHub
- Vehicle's built-in navigation
- Google Maps integration

## Charging Etiquette

### Best Practices:
- Don't charge above 80% at fast chargers during busy times
- Move your car when charging is complete
- Don't unplug others' vehicles
- Report broken chargers
- Keep charging areas clean

## Cost Comparison

### Home Charging:
Average cost: 0.10-0.30 USD per kWh
Typical cost per mile: 0.03-0.08 USD

### Public Charging:
Average cost: 0.20-0.50 USD per kWh
Typical cost per mile: 0.06-0.15 USD

### Gasoline Equivalent:
EV charging often costs 50-70% less than gasoline

## Planning Long Trips

### Pre-Trip Planning:
- Map charging stops
- Check charging network apps
- Have backup options
- Account for weather effects on range

### Cold Weather Tips:
- Range decreases 20-40% in cold weather
- Pre-condition battery while plugged in
- Plan for extra charging stops

## Future of EV Charging

### Coming Improvements:
- Faster charging speeds (350kW+)
- More charging locations
- Wireless charging technology
- Vehicle-to-grid capabilities
- Standardized payment systems
      ''',
      category: 'Electric Vehicles',
      tags: ['electric vehicles', 'charging', 'sustainability', 'technology'],
      imageUrl: 'https://example.com/ev-charging-guide.jpg',
      author: 'Michael Chen',
      publishedDate: DateTime.now().subtract(const Duration(days: 3)),
      readTime: 15,
      rating: 4.9,
      views: 1876,
      isFeatured: true,
    ),
    Guide(
      id: '3',
      title: 'Essential Car Maintenance Schedule',
      subtitle: 'Keep your vehicle running smoothly with proper maintenance',
      description:
          'A detailed maintenance schedule to maximize your vehicle\'s lifespan and performance.',
      content: '''
# Essential Car Maintenance Schedule

## Every Month

### Check These Items:
- Oil level and color
- Tire pressure (including spare)
- Fluid levels (brake, transmission, coolant, windshield washer)
- Lights (headlights, taillights, turn signals)
- Battery terminals for corrosion

## Every 3 Months or 3,000 Miles

### Oil Change Service:
- Change engine oil and filter
- Check air filter (replace if dirty)
- Inspect belts and hoses
- Check battery voltage
- Top off all fluids

## Every 6 Months or 6,000 Miles

### Extended Inspection:
- Rotate tires
- Check tire tread depth
- Inspect brake pads and rotors
- Test air conditioning system
- Check exhaust system
- Inspect suspension components

## Every Year or 12,000 Miles

### Annual Service:
- Replace cabin air filter
- Flush brake fluid (every 2 years)
- Check timing belt
- Inspect fuel system
- Test emissions system
- Professional battery test

## Every 2-3 Years or 24,000-36,000 Miles

### Major Services:
- Replace air filter
- Change transmission fluid
- Replace spark plugs
- Coolant system flush
- Timing belt replacement (if needed)

## Seasonal Maintenance

### Spring Preparation:
- Check air conditioning
- Inspect windshield wipers
- Clean winter salt/debris
- Check tire condition after winter

### Summer Readiness:
- Test cooling system
- Check tire pressure (heat affects pressure)
- Inspect belts for cracking
- Verify air conditioning efficiency

### Fall Preparation:
- Check heating system
- Inspect battery (cold weather stress)
- Check tire tread for winter driving
- Top off antifreeze

### Winter Preparation:
- Install winter tires if needed
- Check battery and charging system
- Inspect windshield wipers
- Keep emergency kit in car

## Warning Signs to Address Immediately

### Engine Issues:
- Check engine light
- Unusual noises or vibrations
- Oil pressure warning
- Temperature gauge in red zone

### Brake Problems:
- Squealing or grinding noises
- Soft or spongy brake pedal
- Vehicle pulls to one side when braking
- Brake warning light

### Tire Concerns:
- Uneven wear patterns
- Bulges or cracks in sidewall
- Tread depth below 2/32 inch
- Frequent pressure loss

## DIY vs. Professional Service

### You Can Do:
- Check fluid levels
- Replace windshield wipers
- Change air filters
- Monitor tire pressure
- Basic visual inspections

### Leave to Professionals:
- Oil changes (unless experienced)
- Brake service
- Transmission work
- Electrical problems
- Engine diagnostics

## Maintenance Cost Planning

### Budget Guidelines:
- Set aside 100-200 USD per month for maintenance
- Higher mileage vehicles need more
- German luxury cars cost more to maintain
- Keep maintenance records for resale value

### Money-Saving Tips:
- Follow manufacturer's schedule (not dealer's)
- Learn basic maintenance tasks
- Shop around for service prices
- Use quality aftermarket parts when appropriate
- Address problems early before they worsen
      ''',
      category: 'Maintenance',
      tags: ['maintenance', 'diy', 'schedule', 'cost-saving'],
      imageUrl: 'https://example.com/maintenance-guide.jpg',
      author: 'David Rodriguez',
      publishedDate: DateTime.now().subtract(const Duration(days: 7)),
      readTime: 10,
      rating: 4.7,
      views: 3210,
      isFeatured: false,
    ),
    Guide(
      id: '4',
      title: 'Understanding Car Insurance: Types and Coverage',
      subtitle: 'Navigate car insurance options to get the best protection',
      description:
          'Comprehensive guide to understanding different types of car insurance and how to choose the right coverage.',
      content: '''
# Understanding Car Insurance: Types and Coverage

## Types of Car Insurance Coverage

### Liability Insurance (Required in most states)

#### Bodily Injury Liability:
- Covers medical expenses for others injured in an accident you cause
- Includes legal fees if you're sued
- Typical coverage: 25,000/50,000 USD or 50,000/100,000 USD

#### Property Damage Liability:
- Covers damage to other people's property
- Includes vehicles, buildings, fences, etc.
- Typical coverage: 25,000-100,000 USD

### Collision Coverage (Optional)
- Covers damage to your car from collisions
- Applies regardless of who's at fault
- Includes hitting other vehicles, objects, or rollovers
- Subject to deductible (250-1,000 USD)

### Comprehensive Coverage (Optional)
- Covers non-collision damage to your car
- Includes theft, vandalism, weather damage, animal strikes
- Also subject to deductible
- Sometimes called "Other Than Collision"

### Personal Injury Protection (PIP)
- Covers medical expenses for you and passengers
- May include lost wages and rehabilitation
- Required in some "no-fault" states
- Also called Medical Payments Coverage

### Uninsured/Underinsured Motorist Coverage
- Protects you when hit by uninsured drivers
- Covers both bodily injury and property damage
- Recommended even if not required
- About 13% of drivers are uninsured nationally

## Additional Coverage Options

### Gap Insurance:
- Covers difference between car's value and loan amount
- Important for new cars that depreciate quickly
- Usually available through dealership or insurer

### Rental Reimbursement:
- Pays for rental car while yours is being repaired
- Typical coverage: 30-50 USD per day for 30 days
- Relatively inexpensive add-on

### Roadside Assistance:
- 24/7 towing and emergency services
- Jump starts, flat tire changes, lockout service
- Often cheaper than AAA membership

## Factors Affecting Insurance Rates

### Personal Factors:
- Age and driving experience
- Driving record and claims history
- Credit score (in most states)
- Location (urban vs. rural)
- Annual mileage

### Vehicle Factors:
- Make, model, and year
- Safety ratings and features
- Theft rates for that model
- Repair costs and parts availability
- Engine size and performance

## How to Save Money on Car Insurance

### Shop Around:
- Get quotes from multiple insurers
- Rates can vary significantly
- Consider both online and local agents
- Review annually or after major life changes

### Increase Deductibles:
- Higher deductibles mean lower premiums
- Make sure you can afford the deductible
- Consider separate deductibles for collision and comprehensive

### Take Advantage of Discounts:
- Multi-policy (bundle with home insurance)
- Multi-vehicle discounts
- Good driver discounts
- Student good grades discounts
- Safety feature discounts
- Low mileage discounts

### Maintain Good Credit:
- Pay bills on time
- Keep credit utilization low
- Monitor credit report for errors
- Credit score significantly impacts rates in most states

## When to Drop Coverage

### Collision and Comprehensive:
Consider dropping when:
- Car value is less than 3,000-4,000 USD
- Annual premium exceeds 10% of car's value
- You have significant savings for replacement

### Never Drop:
- Liability coverage (required by law)
- Uninsured motorist coverage
- Any coverage required by lender

## Making Insurance Claims

### After an Accident:
1. Ensure everyone's safety
2. Call police if required
3. Exchange information with other drivers
4. Document the scene with photos
5. Contact your insurance company immediately
6. Keep detailed records

### Working with Adjusters:
- Be honest and factual
- Provide requested documentation promptly
- Get repair estimates from reputable shops
- Understand your coverage limits
- Ask questions if anything is unclear

## Choosing an Insurance Company

### Research Options:
- Financial stability ratings (A.M. Best, Moody's)
- Customer satisfaction scores (J.D. Power)
- Claims handling reputation
- Local agent availability
- Online tools and mobile apps

### Questions to Ask:
- What discounts are available?
- How are claims typically handled?
- What is the claims settlement process?
- Are there preferred repair shops?
- What payment options are available?
      ''',
      category: 'Insurance',
      tags: ['insurance', 'liability', 'coverage', 'claims'],
      imageUrl: 'https://example.com/insurance-guide.jpg',
      author: 'Jennifer Adams',
      publishedDate: DateTime.now().subtract(const Duration(days: 10)),
      readTime: 14,
      rating: 4.6,
      views: 1654,
      isFeatured: false,
    ),
    Guide(
      id: '5',
      title: 'Best Family Cars for 2024: Safety and Space',
      subtitle: 'Top vehicles that prioritize family safety and comfort',
      description:
          'Detailed review of the best family vehicles focusing on safety ratings, space, and value.',
      content: '''
# Best Family Cars for 2024: Safety and Space

## What Makes a Great Family Car?

### Safety First:
- 5-star NHTSA or IIHS Top Safety Pick awards
- Advanced driver assistance systems
- Multiple airbags and robust crash structure
- Good visibility for the driver

### Space and Comfort:
- Adequate seating for family size
- Generous cargo space
- Easy access to all seating positions
- Climate control for all passengers

### Reliability and Value:
- Strong reliability ratings
- Good resale value
- Reasonable maintenance costs
- Fuel efficiency for family budgets

## Top Midsize SUVs for Families

### 1. Honda Pilot
Starting Price: 38,000 USD
Seating: 8 passengers

Pros:
- Excellent safety ratings
- Spacious three-row seating
- Strong V6 engine
- Honda reliability reputation

Cons:
- Average fuel economy
- Road noise at highway speeds

### 2. Toyota Highlander
Starting Price: 36,000 USD
Seating: 8 passengers

Pros:
- Top-tier reliability
- Hybrid option available
- User-friendly technology
- Strong resale value

Cons:
- Less cargo space than competitors
- Uninspiring driving dynamics

### 3. Mazda CX-9
Starting Price: 35,000 USD
Seating: 7 passengers

Pros:
- Premium interior quality
- Engaging driving experience
- Excellent safety scores
- Stylish exterior design

Cons:
- Tight third-row seating
- Lower reliability ratings

## Best Family Sedans

### 1. Toyota Camry
Starting Price: 25,000 USD
Seating: 5 passengers

Pros:
- Outstanding reliability
- Excellent fuel economy
- Strong safety ratings
- Spacious interior

Cons:
- CVT transmission feel
- Road noise on rough surfaces

### 2. Honda Accord
Starting Price: 26,000 USD
Seating: 5 passengers

Pros:
- Refined ride quality
- Powerful and efficient engines
- Intuitive technology
- Excellent safety scores

Cons:
- Infotainment learning curve
- Premium fuel recommended

### 3. Subaru Legacy
Starting Price: 24,000 USD
Seating: 5 passengers

Pros:
- Standard all-wheel drive
- Excellent safety ratings
- Good fuel economy
- Spacious interior

Cons:
- CVT transmission noise
- Less engaging to drive

## Safety Features to Look For

### Standard Safety Tech:
- Automatic emergency braking
- Blind spot monitoring
- Lane departure warning/keeping
- Rear cross-traffic alert
- Adaptive cruise control

### Advanced Features:
- 360-degree camera systems
- Automatic parking assistance
- Traffic sign recognition
- Driver attention monitoring
- Night vision systems

## Family Car Shopping Tips

### Involve the Whole Family:
- Test drive with car seats installed
- Check ease of loading/unloading
- Ensure everyone can reach controls
- Test third-row access if applicable

### Consider Total Cost of Ownership:
- Fuel costs over 5 years
- Insurance rates for your area
- Maintenance and repair costs
- Depreciation rates

### Timing Your Purchase:
- Model year-end clearances
- Holiday weekend sales
- End of manufacturer's fiscal quarters
- When new models are released

## Child Safety Considerations

### Car Seat Compatibility:
- LATCH system accessibility
- Seat belt length and positioning
- Door opening width
- Ceiling height for installation

### Safety Ratings by Age:
- Infant seats (rear-facing)
- Convertible seats (rear/forward-facing)
- Booster seats (forward-facing)
- Adult seat belt fit

### Additional Safety Tips:
- Never leave children unattended
- Use window shades for UV protection
- Keep emergency supplies in car
- Teach children about car safety

## Future Family Car Trends

### Technology Integration:
- Smartphone connectivity
- Rear-seat entertainment systems
- WiFi hotspots
- Voice control systems

### Electrification:
- More electric family options
- Plug-in hybrid alternatives
- Improved charging infrastructure
- Lower operating costs

### Autonomous Features:
- Highway driving assistance
- Automatic parking
- Traffic jam assistance
- Enhanced safety systems
      ''',
      category: 'Vehicle Reviews',
      tags: ['family cars', 'safety', 'reviews', '2024'],
      imageUrl: 'https://example.com/family-cars-guide.jpg',
      author: 'Emily Johnson',
      publishedDate: DateTime.now().subtract(const Duration(days: 2)),
      readTime: 18,
      rating: 4.9,
      views: 4532,
      isFeatured: true,
    ),
  ];

  // Get all guides
  static List<Guide> getAllGuides() {
    return List.from(_sampleGuides);
  }

  // Get featured guides
  static List<Guide> getFeaturedGuides() {
    return _sampleGuides.where((guide) => guide.isFeatured).toList();
  }

  // Get guides by category
  static List<Guide> getGuidesByCategory(String category) {
    return _sampleGuides.where((guide) => guide.category == category).toList();
  }

  // Get guide by ID
  static Guide? getGuideById(String id) {
    try {
      return _sampleGuides.firstWhere((guide) => guide.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search guides
  static List<Guide> searchGuides(String query) {
    final lowerQuery = query.toLowerCase();
    return _sampleGuides.where((guide) {
      return guide.title.toLowerCase().contains(lowerQuery) ||
          guide.description.toLowerCase().contains(lowerQuery) ||
          guide.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // Get available categories
  static List<GuideCategory> getCategories() {
    return [
      const GuideCategory(
        id: 'buying-guide',
        name: 'Buying Guide',
        description: 'Everything you need to know about purchasing a vehicle',
        iconName: 'shopping_cart',
        color: '4CAF50',
        guideCount: 8,
      ),
      const GuideCategory(
        id: 'maintenance',
        name: 'Maintenance',
        description: 'Keep your vehicle running smoothly',
        iconName: 'build',
        color: 'FF9800',
        guideCount: 12,
      ),
      const GuideCategory(
        id: 'electric-vehicles',
        name: 'Electric Vehicles',
        description: 'The future of transportation',
        iconName: 'electric_car',
        color: '2196F3',
        guideCount: 6,
      ),
      const GuideCategory(
        id: 'insurance',
        name: 'Insurance',
        description: 'Protect yourself and your investment',
        iconName: 'security',
        color: 'E91E63',
        guideCount: 5,
      ),
      const GuideCategory(
        id: 'vehicle-reviews',
        name: 'Vehicle Reviews',
        description: 'In-depth reviews and comparisons',
        iconName: 'star_rate',
        color: 'FF5722',
        guideCount: 15,
      ),
      const GuideCategory(
        id: 'financing',
        name: 'Financing',
        description: 'Smart ways to finance your vehicle',
        iconName: 'account_balance',
        color: '607D8B',
        guideCount: 7,
      ),
    ];
  }

  // Get popular guides (by views)
  static List<Guide> getPopularGuides({int limit = 5}) {
    final sorted = List<Guide>.from(_sampleGuides);
    sorted.sort((a, b) => b.views.compareTo(a.views));
    return sorted.take(limit).toList();
  }

  // Get recent guides
  static List<Guide> getRecentGuides({int limit = 5}) {
    final sorted = List<Guide>.from(_sampleGuides);
    sorted.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
    return sorted.take(limit).toList();
  }
}
