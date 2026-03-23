import 'package:flutter/material.dart';

/// ================= MODELS =================

class TrainerProfile {
  final String name;
  final double rating;
  final int reviews;
  final List<String> specializations;
  final int hourlyRate;
  final String experience;
  final String imageUrl;
  final String about;

  TrainerProfile({
    required this.name,
    required this.rating,
    required this.reviews,
    required this.specializations,
    required this.hourlyRate,
    required this.experience,
    required this.imageUrl,
    required this.about,
  });
}

/// ================= MAIN PAGE =================

class FindTrainerPage extends StatefulWidget {
  const FindTrainerPage({super.key});

  @override
  State<FindTrainerPage> createState() => _FindTrainerPageState();
}

class _FindTrainerPageState extends State<FindTrainerPage> {
  // Mock data based on the provided design
  final List<TrainerProfile> trainers = [
    TrainerProfile(
      name: "Marcus Johnson",
      rating: 4.9,
      reviews: 127,
      specializations: ["Strength Training", "HIIT"],
      hourlyRate: 85,
      experience: "10+ years",
      imageUrl: "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
      about: "Certified professional with 10+ years of experience. Specializing in strength and conditioning. Committed to helping clients achieve peak physical performance.",
    ),
    TrainerProfile(
      name: "Sophia Rivera",
      rating: 5.0,
      reviews: 203,
      specializations: ["Weight Loss", "Nutrition"],
      hourlyRate: 95,
      experience: "8 years",
      imageUrl: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
      about: "Results-driven trainer focusing on holistic wellness. I combine nutrition coaching with personalized training to help clients lose weight and develop healthier habits.",
    ),
    TrainerProfile(
      name: "Lily Anderson",
      rating: 4.8,
      reviews: 89,
      specializations: ["Yoga", "Meditation", "Flexibility"],
      hourlyRate: 70,
      experience: "6 years",
      imageUrl: "https://images.unsplash.com/photo-1518611012118-696072aa579a?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
      about: "Certified professional with 6 years of experience. Specializing in Yoga, Meditation, Flexibility. Committed to helping clients achieve their fitness goals through personalized training programs.",
    ),
    TrainerProfile(
      name: "Derek Thompson",
      rating: 4.9,
      reviews: 156,
      specializations: ["CrossFit", "Olympic Lifting"],
      hourlyRate: 90,
      experience: "12 years",
      imageUrl: "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
      about: "Former competitive lifter turning everyday athletes into powerhouses. Focuses on form, explosive power, and functional CrossFit mechanics.",
    ),
    TrainerProfile(
      name: "Rachel Green",
      rating: 4.7,
      reviews: 94,
      specializations: ["Nutrition Coaching", "Meal Planning"],
      hourlyRate: 75,
      experience: "7 years",
      imageUrl: "https://images.unsplash.com/photo-1552697611-40b54fbd9eb3?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
      about: "Dietitian and fitness coach. I believe abs are made in the kitchen. Let's build a sustainable meal and workout plan that fits your busy lifestyle.",
    ),
    TrainerProfile(
      name: "Tyler Brooks",
      rating: 4.8,
      reviews: 112,
      specializations: ["Sports Performance", "Agility Training"],
      hourlyRate: 100,
      experience: "9 years",
      imageUrl: "https://images.unsplash.com/photo-1564434256729-1b327b878345?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80",
      about: "Specializing in athletic conditioning. Whether you want to improve your sprint time or vertical jump, I have the drills to get you there.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.person_search, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text("Find a Trainer", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          // Makes the grid responsive: 1 column on small phones, 2+ on tablets/web
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85, 
          ),
          itemCount: trainers.length,
          itemBuilder: (context, index) {
            return _buildTrainerCard(context, trainers[index]);
          },
        ),
      ),
    );
  }

  /// ================= TRAINER CARD =================

  Widget _buildTrainerCard(BuildContext context, TrainerProfile trainer) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showTrainerDetails(context, trainer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(trainer.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Bottom Content
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trainer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "${trainer.rating} ",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              "(${trainer.reviews} reviews)",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    // Specialization Tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: trainer.specializations.take(2).map((spec) => _buildTag(spec)).toList()
                        ..addAll(trainer.specializations.length > 2 
                            ? [_buildTag("+${trainer.specializations.length - 2}", isGrey: true)] 
                            : []),
                    ),

                    const Divider(height: 1),

                    // Footer: Rate and Experience
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("\$${trainer.hourlyRate}/hr", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(trainer.experience, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {bool isGrey = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGrey ? Colors.grey.shade200 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isGrey ? Colors.grey.shade700 : Colors.blue.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ================= MODAL DIALOG =================

  void _showTrainerDetails(BuildContext context, TrainerProfile trainer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 400, // Fixed max width for larger screens
            color: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image & Close Button Stack
                  Stack(
                    children: [
                      Image.network(
                        trainer.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 20, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Content Details
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trainer.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text("${trainer.rating} ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text("(${trainer.reviews} reviews) • ${trainer.experience} exp", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        Text("Specializations", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: trainer.specializations.map((spec) => _buildTag(spec)).toList(),
                        ),

                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Hourly Rate", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text("\$${trainer.hourlyRate}/hour", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        Text("About", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(
                          trainer.about,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),

                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.person_add, color: Colors.white),
                            label: const Text("Send Connection Request", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Connection request sent to ${trainer.name}!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}