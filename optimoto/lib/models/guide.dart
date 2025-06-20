class Guide {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String content;
  final String category;
  final List<String> tags;
  final String imageUrl;
  final String author;
  final DateTime publishedDate;
  final int readTime; // in minutes
  final double rating;
  final int views;
  final bool isFeatured;

  const Guide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.content,
    required this.category,
    required this.tags,
    required this.imageUrl,
    required this.author,
    required this.publishedDate,
    required this.readTime,
    required this.rating,
    required this.views,
    this.isFeatured = false,
  });

  factory Guide.fromJson(Map<String, dynamic> json) {
    return Guide(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl']?.toString() ?? '',
      author: json['author']?.toString() ?? 'OptiMoto Team',
      publishedDate: json['publishedDate'] != null
          ? DateTime.parse(json['publishedDate'])
          : DateTime.now(),
      readTime: json['readTime'] as int? ?? 5,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      views: json['views'] as int? ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'content': content,
      'category': category,
      'tags': tags,
      'imageUrl': imageUrl,
      'author': author,
      'publishedDate': publishedDate.toIso8601String(),
      'readTime': readTime,
      'rating': rating,
      'views': views,
      'isFeatured': isFeatured,
    };
  }
}

class GuideCategory {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final String color;
  final int guideCount;

  const GuideCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.color,
    required this.guideCount,
  });
}
