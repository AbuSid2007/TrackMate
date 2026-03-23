import 'package:flutter/material.dart';

/// ================= MODELS =================

class User {
  final String name;
  final int steps;
  User(this.name, this.steps);
}

class FriendRequest {
  final String name;
  FriendRequest(this.name);
}

class Challenge {
  final String title;
  final String reward;
  Challenge(this.title, this.reward);
}

class Post {
  final String user;
  final String content;
  int likes;
  final String timeAgo;

  Post(this.user, this.content, this.likes, this.timeAgo);
}

/// ================= MAIN PAGE =================

class SocialTrainersPage extends StatefulWidget {
  const SocialTrainersPage({super.key});

  @override
  State<SocialTrainersPage> createState() => _SocialTrainersPageState();
}

class _SocialTrainersPageState extends State<SocialTrainersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<User> leaderboard = [
    User("Sarah Johnson", 12450),
    User("Mike Chen", 11890),
    User("Jessica Martinez", 10250),
    User("David Kim", 9870),
    User("Alex Rodriguez", 7500),
  ];

  List<FriendRequest> requests = [
    FriendRequest("Emma Thompson"),
    FriendRequest("Chris Evans"),
  ];

  List<Challenge> challenges = [
    Challenge("IITK 50k Step Weekend", "500 XP"),
    Challenge("7-Day Streak Challenge", "Profile Badge"),
    Challenge("Burn 2000 Calories", "300 XP"),
  ];

  List<Post> posts = [
    Post("Sarah Johnson", "Hit a new PR on squats today! 💪 Feels amazing.", 12, "2h ago"),
    Post("Mike Chen", "5-day workout streak complete 🔥 Keeping the momentum going.", 8, "4h ago"),
  ];

  final TextEditingController _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    super.dispose();
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Community", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Feed"),
            Tab(text: "Leaderboard"),
            Tab(text: "Trainer"),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.group_add),
                onPressed: _openRequests,
              ),
              if (requests.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${requests.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeed(),
          _buildFriends(),
          _buildTrainerChat(),
        ],
      ),
    );
  }

  /// ================= FEED =================

  Widget _buildFeed() {
    return Column(
      children: [
        _buildChallenges(),
        const Divider(thickness: 1, height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildCreatePostCard();
              final post = posts[index - 1];
              return _buildPostCard(post);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreatePostCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _postController,
                decoration: const InputDecoration(
                  hintText: "Share your workout updates...",
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: () {
                if (_postController.text.isNotEmpty) {
                  setState(() {
                    posts.insert(0, Post("Me", _postController.text, 0, "Just now"));
                    _postController.clear();
                  });
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: Text(post.user[0], style: const TextStyle(color: Colors.black87)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(post.timeAgo, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: () => setState(() => post.likes++),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: post.likes > 0 ? Colors.redAccent : Colors.grey, size: 20),
                      const SizedBox(width: 4),
                      Text("${post.likes} Likes"),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.comment_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 4),
                const Text("Comment"),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// ================= CHALLENGES =================

  Widget _buildChallenges() {
    return Container(
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: challenges.map((c) => Container(
          width: 220,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade700]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(c.reward, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                    child: const Text("JOIN", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ],
          ),
        )).toList(),
      ),
    );
  }

  /// ================= FRIENDS LEADERBOARD =================

  Widget _buildFriends() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search trackmates...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final user = leaderboard[index];
              
              // Medal Colors for top 3
              Color avatarColor = Colors.grey.shade300;
              Color iconColor = Colors.black54;
              if (index == 0) { avatarColor = Colors.amber.shade100; iconColor = Colors.amber.shade800; }
              else if (index == 1) { avatarColor = Colors.grey.shade300; iconColor = Colors.grey.shade700; }
              else if (index == 2) { avatarColor = Colors.brown.shade200; iconColor = Colors.brown.shade800; }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: avatarColor,
                      child: Text("${index + 1}", style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    if (index < 3)
                      const Icon(Icons.emoji_events, size: 18, color: Colors.amber)
                  ],
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                subtitle: Text("${user.steps} steps this week", style: TextStyle(color: Colors.green.shade600)),
                trailing: IconButton(
                  icon: const Icon(Icons.waving_hand_outlined, color: Colors.blueAccent),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Waved at ${user.name}!')));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// ================= FRIEND REQUESTS =================

  void _openRequests() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("Pending Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 16),
                if (requests.isEmpty)
                  const Text("No pending requests.", style: TextStyle(color: Colors.grey)),
                ...requests.map((r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(r.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: const CircleBorder(), padding: const EdgeInsets.all(8)),
                        onPressed: () {
                          setState(() { leaderboard.add(User(r.name, 0)); requests.remove(r); });
                          setModalState(() {});
                        },
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, shape: const CircleBorder(), padding: const EdgeInsets.all(8)),
                        onPressed: () {
                          setState(() => requests.remove(r));
                          setModalState(() {});
                        },
                        child: const Icon(Icons.close, color: Colors.black54, size: 20),
                      )
                    ],
                  ),
                )),
              ],
            );
          }
        );
      },
    );
  }

  /// ================= TRAINER CHAT =================

  Widget _buildTrainerChat() {
    return Column(
      children: [
        /// Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(radius: 22, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                  )
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Marcus Johnson", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Certified Personal Trainer", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.calendar_month, color: Colors.blueAccent), onPressed: _bookSession, tooltip: "Book Session"),
              IconButton(icon: const Icon(Icons.star_rate, color: Colors.amber), onPressed: _leaveReview, tooltip: "Leave Review"),
            ],
          ),
        ),

        /// Chat messages
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _ChatBubble(text: "Hi! I reviewed your lifting form from yesterday's video.", isMe: false, time: "10:00 AM"),
                _ChatBubble(text: "Your squat depth is getting much better! Just remember to keep your chest up.", isMe: false, time: "10:01 AM"),
                _ChatBubble(text: "Thanks Marcus! I felt a lot more stable this time.", isMe: true, time: "10:05 AM"),
              ],
            ),
          ),
        ),

        /// Input Area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: SafeArea(
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey), onPressed: () {}),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Message Marcus...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  /// ================= BOOK SESSION =================

  void _bookSession() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Book a Session"),
        content: const Text("Pulling up Marcus's availability calendar..."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Continue")),
        ],
      ),
    );
  }

  /// ================= REVIEW =================

  void _leaveReview() {
    showDialog(
      context: context,
      builder: (_) {
        int rating = 5;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Rate your Trainer", textAlign: TextAlign.center),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setState(() => rating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Write your review...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Submit Review")),
          ],
        );
      },
    );
  }
}

/// ================= CHAT BUBBLE =================

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  const _ChatBubble({required this.text, required this.isMe, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blueAccent : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
          ),
          const SizedBox(height: 4),
          Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}