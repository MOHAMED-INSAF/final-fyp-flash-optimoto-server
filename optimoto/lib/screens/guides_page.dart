import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/guide.dart';
import '../services/guides_service.dart';
import '../theme/app_theme.dart';
import 'guide_detail_page.dart';
import 'guides_category_page.dart';

class GuidesPage extends StatefulWidget {
  const GuidesPage({super.key});

  @override
  State<GuidesPage> createState() => _GuidesPageState();
}

class _GuidesPageState extends State<GuidesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Guide> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = GuidesService.searchGuides(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryLight,
                      AppTheme.primaryDark,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.menu_book,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search guides and tips...',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: _performSearch,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Featured'),
                Tab(text: 'Categories'),
                Tab(text: 'Popular'),
              ],
            ),
          ),

          // Content
          if (_isSearching)
            _buildSearchResults()
          else
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFeaturedTab(),
                  _buildCategoriesTab(),
                  _buildPopularTab(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Search Results',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_searchResults.length} found',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_searchResults.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No guides found matching your search.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                return _buildGuideCard(_searchResults[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTab() {
    final featuredGuides = GuidesService.getFeaturedGuides();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Guides',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our top picks for essential automotive knowledge',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ...featuredGuides.map((guide) => _buildFeaturedGuideCard(guide)),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final categories = GuidesService.getCategories();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse by Category',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _buildCategoryCard(categories[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTab() {
    final popularGuides = GuidesService.getPopularGuides(limit: 10);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most Popular',
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The guides our community loves most',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ...popularGuides.asMap().entries.map((entry) {
            final index = entry.key;
            final guide = entry.value;
            return _buildPopularGuideCard(guide, index + 1);
          }),
        ],
      ),
    );
  }

  Widget _buildFeaturedGuideCard(Guide guide) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToGuideDetail(guide),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [
                    _getCategoryColor(guide.category).withOpacity(0.8),
                    _getCategoryColor(guide.category).withOpacity(0.6),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _getCategoryIcon(guide.category),
                      size: 60,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'FEATURED',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(guide.category)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          guide.category,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _getCategoryColor(guide.category),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${guide.readTime} min read',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    guide.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    guide.subtitle,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            guide.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(Icons.visibility,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${guide.views}',
                            style: GoogleFonts.inter(
                                fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'By ${guide.author}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard(Guide guide) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(guide.category).withOpacity(0.1),
          child: Icon(
            _getCategoryIcon(guide.category),
            color: _getCategoryColor(guide.category),
          ),
        ),
        title: Text(
          guide.title,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(guide.subtitle),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  guide.category,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _getCategoryColor(guide.category),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text('• ${guide.readTime} min'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        isThreeLine: true,
        onTap: () => _navigateToGuideDetail(guide),
      ),
    );
  }

  Widget _buildCategoryCard(GuideCategory category) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToCategoryPage(category),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(int.parse('0xFF${category.color}')).withOpacity(0.1),
                Color(int.parse('0xFF${category.color}')).withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getIconFromName(category.iconName),
                size: 32,
                color: Color(int.parse('0xFF${category.color}')),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${category.guideCount} guides',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularGuideCard(Guide guide, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: rank <= 3
                ? Colors.amber
                : AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        title: Text(
          guide.title,
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.visibility, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${guide.views} views'),
            const SizedBox(width: 12),
            Icon(Icons.star, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(guide.rating.toStringAsFixed(1)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToGuideDetail(guide),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'buying guide':
        return const Color(0xFF4CAF50);
      case 'maintenance':
        return const Color(0xFFFF9800);
      case 'electric vehicles':
        return const Color(0xFF2196F3);
      case 'insurance':
        return const Color(0xFFE91E63);
      case 'vehicle reviews':
        return const Color(0xFFFF5722);
      case 'financing':
        return const Color(0xFF607D8B);
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'buying guide':
        return Icons.shopping_cart;
      case 'maintenance':
        return Icons.build;
      case 'electric vehicles':
        return Icons.electric_car;
      case 'insurance':
        return Icons.security;
      case 'vehicle reviews':
        return Icons.star_rate;
      case 'financing':
        return Icons.account_balance;
      default:
        return Icons.article;
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'build':
        return Icons.build;
      case 'electric_car':
        return Icons.electric_car;
      case 'security':
        return Icons.security;
      case 'star_rate':
        return Icons.star_rate;
      case 'account_balance':
        return Icons.account_balance;
      default:
        return Icons.article;
    }
  }

  void _navigateToGuideDetail(Guide guide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuideDetailPage(guide: guide),
      ),
    );
  }

  void _navigateToCategoryPage(GuideCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuidesCategoryPage(category: category),
      ),
    );
  }
}
