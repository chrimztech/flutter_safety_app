// pages/user_profile_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Make sure this import is present and correct
import 'dart:io'; // For File operations

// A simple data model for the user profile
class UserProfile {
  String name;
  String email;
  String? phone;
  String? location;
  String? aboutMe;
  String? profileImageUrl; // Can be local path or network URL

  UserProfile({
    required this.name,
    required this.email,
    this.phone,
    this.location,
    this.aboutMe,
    this.profileImageUrl,
  });

  // Factory constructor for initial dummy data or from JSON
  factory UserProfile.dummy() {
    return UserProfile(
      name: 'Chrishent Matakala',
      email: 'chrishent@example.com',
      phone: '+260 971 234567',
      location: 'Lusaka, Zambia',
      aboutMe: 'Passionate about environmental sustainability and community development.',
      profileImageUrl: 'https://via.placeholder.com/150/0000FF/FFFFFF?text=CM', // Placeholder image
      // For local asset: 'assets/profile.jpg', (make sure it exists in pubspec.yaml)
    );
  }
}

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<UserProfile> _userProfileFuture; // To simulate fetching user data
  File? _pickedImage; // To store the picked image file

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _aboutMeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _fetchUserProfile(); // Start fetching data
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  // Simulate fetching user profile data
  Future<UserProfile> _fetchUserProfile() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    final dummyProfile = UserProfile.dummy();

    // Initialize controllers with fetched data
    _nameController.text = dummyProfile.name;
    _emailController.text = dummyProfile.email;
    _phoneController.text = dummyProfile.phone ?? '';
    _locationController.text = dummyProfile.location ?? '';
    _aboutMeController.text = dummyProfile.aboutMe ?? '';

    // Correct handling for previously picked local image paths if stored
    if (dummyProfile.profileImageUrl != null) {
      if (dummyProfile.profileImageUrl!.startsWith('file://')) {
        _pickedImage = File(dummyProfile.profileImageUrl!.replaceFirst('file://', ''));
      }
      // For assets or network images, _pickedImage remains null,
      // and the CircleAvatar will use the backgroundImage property.
    }

    return dummyProfile;
  }

  // Function to handle picking an image
  Future<void> _pickImage() async {
    // FIX: Correctly instantiate ImagePicker
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      // In a real app, you would upload this image to a server
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated! (Simulated upload)')),
      );
    }
  }

  // Simulate updating profile information
  void _updateProfile() {
    // In a real app, send data from controllers to backend
    final updatedProfile = UserProfile(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      location: _locationController.text,
      aboutMe: _aboutMeController.text,
      profileImageUrl: _pickedImage?.path, // Or server URL after upload
    );

    // Simulate saving
    print('Updating profile: ${updatedProfile.name}, ${updatedProfile.email}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
    // You might re-fetch _userProfileFuture or update state directly
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'User Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.primaryColor,
        elevation: 6,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              // Can navigate to a dedicated "Edit Profile" page
              _showEditProfileBottomSheet(context);
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: FutureBuilder<UserProfile>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.primaryColor));
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading profile: ${snapshot.error}', style: TextStyle(color: Colors.red)),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No profile data available.'));
          }

          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      // Conditional logic for backgroundImage
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) // Use picked image if available
                          : (user.profileImageUrl != null && user.profileImageUrl!.startsWith('http')
                              ? NetworkImage(user.profileImageUrl!) // Use network image if URL starts with http
                              : (user.profileImageUrl != null && user.profileImageUrl!.startsWith('assets/')
                                  ? AssetImage(user.profileImageUrl!) // Use asset image if URL starts with assets/
                                  : null)
                            ) as ImageProvider?, // Cast to ImageProvider? to satisfy type system
                      child: _pickedImage == null && // If no image picked AND...
                              (user.profileImageUrl == null || // ...no profile URL OR...
                                !user.profileImageUrl!.startsWith('http') && // ...not a network URL AND...
                                !user.profileImageUrl!.startsWith('assets/')) // ...not an asset URL
                          ? Icon(Icons.person, size: 70, color: theme.primaryColor) // Show default person icon
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          backgroundColor: theme.primaryColor,
                          radius: 20,
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  user.name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // Profile Details Section
                _buildProfileSection(context, 'Contact Information', Icons.contact_mail, [
                  _buildProfileInfoRow(context, Icons.phone, user.phone ?? 'N/A'),
                  _buildProfileInfoRow(context, Icons.location_on, user.location ?? 'N/A'),
                ]),
                const SizedBox(height: 24),

                _buildProfileSection(context, 'About Me', Icons.info_outline, [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      user.aboutMe ?? 'No description provided.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                // Other Actions/Sections
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.bar_chart, color: theme.colorScheme.secondary),
                        title: const Text('My Contributions'),
                        subtitle: const Text('View your reports and environmental impact.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('My Contributions page coming soon!')),
                          );
                          // Navigator.pushNamed(context, '/my_contributions');
                        },
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.lock, color: theme.colorScheme.secondary),
                        title: const Text('Account Security'),
                        subtitle: const Text('Change password, manage linked accounts.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account Security settings coming soon!')),
                          );
                          // Navigator.pushNamed(context, '/account_security');
                        },
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      ListTile(
                        leading: Icon(Icons.settings, color: theme.colorScheme.secondary),
                        title: const Text('App Settings'),
                        subtitle: const Text('Adjust app preferences.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(context, '/settings'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),

    );
  }

  // Helper widget for a section header
  Widget _buildProfileSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for a single profile info row
  Widget _buildProfileInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Sheet for Editing Profile
  void _showEditProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows content to take full height
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Make column wrap its content
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  readOnly: true, // Email often not editable without verification
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _aboutMeController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'About Me',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _updateProfile(); // Call the update logic
                    Navigator.pop(sheetContext); // Close the bottom sheet
                    // Refresh the future builder or directly update state if using state management
                    setState(() {
                      _userProfileFuture = _fetchUserProfile(); // Re-fetch to update UI
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}