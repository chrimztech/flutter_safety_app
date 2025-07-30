// pages/virtualisation_page.dart
import 'package:flutter/material.dart';
// Assuming quickaccess_bar.dart is in the same 'widgets' directory
import 'quickaccess_bar.dart';

class VirtualizationPage extends StatelessWidget {
  const VirtualizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Virtualization & Green IT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700, // A more "green" color theme
        elevation: 6,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20.0), // Padding for the bottom to accommodate QuickAccessBar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image/Banner
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/virtualization_banner.jpg'), // Add an image here!
                  fit: BoxFit.cover,
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Powering a Greener Future',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: const Offset(2.0, 2.0),
                            blurRadius: 3.0,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How Virtualization contributes to Environmental Safety & Sustainability.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                        shadows: [
                          Shadow(
                            offset: const Offset(1.0, 1.0),
                            blurRadius: 2.0,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Virtualization is more than just an IT efficiency tool; it\'s a fundamental shift towards sustainable computing. By optimizing resource use, it directly mitigates the environmental impact of modern data centers.',
                style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            _buildExpandableSection(
              context,
              '1. Drastically Reduced Energy Consumption',
              Icons.energy_savings_leaf, // A more specific icon
              [
                _buildInfoCard(
                  context,
                  'Server Consolidation',
                  'By running multiple virtual machines (VMs) on fewer physical servers, virtualization dramatically increases hardware utilization (up to 80%+) from typical low rates (10-15%). This directly cuts down the total number of active servers required.',
                  Colors.green.shade400,
                ),
                _buildInfoCard(
                  context,
                  'Lower Power & Cooling Demand',
                  'Fewer physical servers mean a significant reduction in electricity consumption for both powering IT equipment and, crucially, for the extensive cooling systems that are major energy drains in data centers. This leads to substantial energy savings.',
                  Colors.blue.shade400,
                ),
                _buildInfoCard(
                  context,
                  'Intelligent Power Management',
                  'Advanced virtualization platforms incorporate dynamic power management features. These capabilities allow servers to adjust their power consumption based on real-time workload demands, preventing energy waste during idle or low-activity periods.',
                  Colors.orange.shade400,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildExpandableSection(
              context,
              '2. Minimized Carbon Footprint',
              Icons.cloud_off_outlined,
              [
                _buildInfoCard(
                  context,
                  'Reduced Greenhouse Gas Emissions',
                  'Given that a significant portion of global electricity generation still relies on fossil fuels, reducing energy consumption through virtualization directly translates into a decrease in harmful greenhouse gas emissions, especially carbon dioxide (CO2).',
                  Colors.grey.shade600,
                ),
                _buildInfoCard(
                  context,
                  'Pillar of "Green IT"',
                  'Virtualization is not just a benefit; it\'s a foundational technology for "Green IT" initiatives. It enables organizations to actively pursue more energy-efficient and environmentally responsible computing practices, contributing to broader sustainability goals.',
                  Colors.lightGreen.shade600,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildExpandableSection(
              context,
              '3. Significant Decrease in E-Waste',
              Icons.recycling, // More suitable icon for recycling/e-waste
              [
                _buildInfoCard(
                  context,
                  'Extended Hardware Lifespan',
                  'By optimizing the use of existing hardware, virtualization prolongs the functional life of physical servers and other IT equipment. This reduces the frequency of hardware replacements, directly cutting down the volume of hazardous electronic waste (e-waste) generated, which contains harmful materials like lead, mercury, and cadmium.',
                  Colors.brown.shade400,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildExpandableSection(
              context,
              '4. Optimized Resource & Space Utilization',
              Icons.data_usage, // More general resource usage icon
              [
                _buildInfoCard(
                  context,
                  'Efficient Hardware Utilization',
                  'Virtualization ensures that all computing resources – CPU cycles, memory, and storage – are allocated and used far more efficiently across the entire IT infrastructure. This optimal utilization minimizes redundancy and the need for new hardware purchases.',
                  Colors.purple.shade400,
                ),
                _buildInfoCard(
                  context,
                  'Reduced Data Center Footprint',
                  'Fewer physical servers directly translate to less physical space required for data centers. This is particularly advantageous in urban areas where real estate is costly and energy resources are constrained, allowing for more compact and efficient data centers.',
                  Colors.indigo.shade400,
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildExpandableSection(
              context,
              '5. Facilitating Broader Sustainable Practices',
              Icons.spa, // Nature/sustainability icon
              [
                _buildInfoCard(
                  context,
                  'Enabling Cloud Computing',
                  'Virtualization is the core technology underpinning cloud computing. Migrating to cloud environments allows businesses to leverage hyper-scale data centers, which often boast superior energy efficiency, advanced cooling techniques, and increasing adoption of renewable energy sources by major cloud providers.',
                  Colors.teal.shade700,
                ),
                _buildInfoCard(
                  context,
                  'Virtual Desktop Infrastructure (VDI)',
                  'VDI enables users to access secure, personalized virtual desktops remotely. This reduces the need for individual, energy-consuming physical desktop machines, centralizes management, and allows for the implementation of uniform power policies across all user endpoints, reducing their collective environmental impact.',
                  Colors.deepOrange.shade400,
                ),
                _buildInfoCard(
                  context,
                  'Data Virtualization & Optimization',
                  'Beyond server and desktop virtualization, data virtualization can reduce the necessity for dedicated servers for data replication and streamline data flow. This leads to further energy savings and a smaller carbon footprint by minimizing redundant data movement, improving data quality, and enhancing overall data management efficiency.',
                  Colors.cyan.shade400,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'In summary, virtualization is a transformative technology that shifts IT infrastructure from a collection of underutilized, energy-intensive physical machines to an agile, highly efficient, and environmentally responsible ecosystem. It\'s an indispensable tool for organizations committed to reducing their ecological footprint and actively contributing to a more sustainable global future.',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const QuickAccessBar(currentLabel: 'Virtualization'),
    );
  }

  // --- Helper Widgets ---

  Widget _buildExpandableSection(
      BuildContext context, String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Theme(
        // Override default ExpansionTile color to match app theme
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          leading: Icon(icon, color: Colors.green.shade700, size: 32),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String description, Color iconColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1), // Lighter background based on icon color
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: iconColor.withOpacity(0.5), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: iconColor, size: 24), // Filled circle for emphasis
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900, // Consistent darker green
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}