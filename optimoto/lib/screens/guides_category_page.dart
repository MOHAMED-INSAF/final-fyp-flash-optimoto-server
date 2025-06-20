import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/guide.dart';
import '../services/guides_service.dart';
import '../theme/app_theme.dart';
import 'guide_detail_page.dart';

class GuidesCategoryPage extends StatefulWidget {
  final GuideCategory category;

  const GuidesCategoryPage({super.key, required this.category});

  @override
  State<GuidesCategoryPage> createState() => _GuidesCategoryPageState();
}

class _GuidesCategoryPageState extends State<GuidesCategoryPage> {
  List<Guide> _guides = [];
  String _sortBy = 'recent';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  void _loadGuides() {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final guides = GuidesService.getGuidesByCategory(widget.category.name);
      _sortGuides(guides);

      if (mounted) {
        setState(() {
          _guides = guides;
          _isLoading = false;
        });
      }
    });
  }

  void _sortGuides(List<Guide> guides) {
    switch (_sortBy) {
      case 'recent':
        guides.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
        break;
      case 'popular':
        guides.sort((a, b) => b.views.compareTo(a.views));
        break;
      case 'rating':
        guides.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'read_time':
        guides.sort((a, b) => a.readTime.compareTo(b.readTime));
        break;
    }
  }

  void _changeSorting(String newSort) {
    setState(() {
      _sortBy = newSort;
    });
    _sortGuides(_guides);
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(int.parse('0xFF${widget.category.color}'));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: categoryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.category.name,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryColor,
                      categoryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getIconFromName(widget.category.iconName),
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    Positioned(
                      bottom: 60,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.description,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort, color: Colors.white),
                onSelected: _changeSorting,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'recent',
                    child: Row(
                      children: [
                        Icon(Icons.schedule),
                        SizedBox(width: 8),
                        Text('Most Recent'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'popular',
                    child: Row(
                      children: [
                        Icon(Icons.trending_up),
                        SizedBox(width: 8),
                        Text('Most Popular'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rating',
                    child: Row(
                      children: [
                        Icon(Icons.star),
                        SizedBox(width: 8),
                        Text('Highest Rated'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'read_time',
                    child: Row(
                      children: [
                        Icon(Icons.timer),
                        SizedBox(width: 8),
                        Text('Quick Reads'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Sort indicator and count
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getSortIcon(),
                    color: categoryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getSortLabel(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: categoryColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_guides.length} guides',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Guides List
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_guides.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No guides available',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new content',
                      style: GoogleFonts.inter(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildGuideCard(_guides[index], index),
                  childCount: _guides.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(Guide guide, int index) {
    final categoryColor = Color(int.parse('0xFF${widget.category.color}'));

    return Card(
      margin: EdgeInsets.only(
        bottom: 16,
        top: index == 0 ? 8 : 0,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToGuide(guide),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with featured badge and rating
              Row(
                children: [
                  if (guide.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
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
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        guide.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title and subtitle
              Text(
                guide.title,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              Text(
                guide.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Tags
              if (guide.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: guide.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: categoryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Footer with metadata
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: categoryColor.withOpacity(0.1),
                    child: Text(
                      guide.author[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    guide.author,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${guide.readTime} min',
                        style:
                            GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.visibility,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${guide.views}',
                        style:
                            GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  IconData _getSortIcon() {
    switch (_sortBy) {
      case 'recent':
        return Icons.schedule;
      case 'popular':
        return Icons.trending_up;
      case 'rating':
        return Icons.star;
      case 'read_time':
        return Icons.timer;
      default:
        return Icons.sort;
    }
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'recent':
        return 'Sorted by Most Recent';
      case 'popular':
        return 'Sorted by Most Popular';
      case 'rating':
        return 'Sorted by Highest Rated';
      case 'read_time':
        return 'Sorted by Quick Reads';
      default:
        return 'Sorted';
    }
  }

  void _navigateToGuide(Guide guide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuideDetailPage(guide: guide),
      ),
    );
  }
}
