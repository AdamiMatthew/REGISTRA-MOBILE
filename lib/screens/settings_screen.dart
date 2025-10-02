import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:final_project/screens/login_screen.dart';
import 'package:final_project/widgets/custom_dialogs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _openOfficialPage() async {
    final uri = Uri.parse('https://icpepncr.org/aboutus');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openAboutUs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Us'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Mission',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('ICpEP aims to:'),
                SizedBox(height: 6),
                Text(
                    '• Build a network of professionals and graduates of computer engineering in the country through member interaction and open communication. This is directed to the industry, academe, and government.'),
                SizedBox(height: 6),
                Text(
                    '• Support the professional career of members through relevant training and exposure.'),
                SizedBox(height: 6),
                Text(
                    '• Expand knowledge and specialization in computer engineering through research and development.'),
                SizedBox(height: 16),
                Text('Vision',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(
                    'ICpEP envisions itself as the foundation of world-class Filipino computer engineering professionals and the motivator of interest towards excellence in computer engineering as a field of specialization.'),
                SizedBox(height: 16),
                Text('ICpEP NCR Officers 2024',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Executive Members'),
                SizedBox(height: 6),
                Text('Dr. Roben A. Juanatas, PCpE — President'),
                Text('Dr. Irish C. Juanatas, PCpE — VP for Internal Affairs'),
                Text('Dr. Marie Luvett I. Goh, PCpE — VP for External Affairs'),
                Text('Dr. Jay-ar P. Lalata, PCpE — VP for Education'),
                Text('Engr. Sergio R. Peruda Jr., PCpE — Secretary'),
                Text('Engr. Monette M. Loy-a, PCpE — Treasurer'),
                Text('Engr. Heintjie N. Vicente, PCpE — Auditor'),
                SizedBox(height: 8),
                Text('Committee Members'),
                SizedBox(height: 6),
                Text('Dr. Joselito Eduard E. Goh, PCpE'),
                Text('Dr. Nelson C. Rodelas, PCpE'),
                Text('Dr. Jocelyn F. Villaverde, PCpE'),
                Text('Engr. Honeylet D. Grimaldo, PCpE'),
                Text('Engr. Ana Antoniette C. Illahi, PCpE'),
                Text('Engr. Evangeline P. Lubao, PCpE'),
                Text('Engr. Rico M. Manalo, PCpE'),
                Text('Engr. Yolanda D. Austria, PCpE'),
                Text('Engr. Kenn Arion B. Wong, PCpE'),
                SizedBox(height: 16),
                Text('Past Presidents',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Dr. Irish C. Juanatas, PCpE — 2021-2022'),
                Text('Engr. Maria Cecille A. Venal, PCpE — 2018-2020'),
                Text('Engr. Noel B. Linsangan, PCpE — 2014-2017'),
                Text('Engr. Lorenzo B. Sta. Maria Jr., PCpE — 2011-2013'),
                Text('Engr. Alexander B. Ybasco † — 2010-2011'),
                Text('Engr. Erwin G. Mendoza, PCpE — 2008-2010'),
                SizedBox(height: 16),
                Text('History',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('The Early Years'),
                SizedBox(height: 6),
                Text(
                    'In 1992, a group of computer engineers formed the Philippine Institute of Computer Engineers, Inc. (PhICEs). PhICEs initially gathered a number of professional members and held conventions, seminars, and symposia in various regions across Luzon and Visayas. However, after some years of activity, the organization became inactive.'),
                SizedBox(height: 10),
                Text('Revival and Rebranding'),
                SizedBox(height: 6),
                Text(
                    'In 2008, computer engineers from different organizations, led by Engr. Erwin G. Mendoza and Engr. Alexander B. Ybasco, came together to revive the organization. After several meetings, the group decided to change the name to the Institute of Computer Engineers of the Philippines, Inc. (ICpEP), marking a fresh start for the professional body.'),
                SizedBox(height: 10),
                Text('Industry Partnerships'),
                SizedBox(height: 6),
                Text(
                    'Since then, ICpEP has established strong partnerships with the industry. Leading companies such as Intel, Microsoft, HP, Lenovo, Epson, and Red Fox recognize ICpEP as the sole organization for computer engineers in the Philippines. Additionally, ICpEP collaborated with SM Mall of Asia and NIDO Fortified Science Discovery Center to promote research and development through exhibitions of notable computer engineering projects.'),
                SizedBox(height: 10),
                Text('Academic Expansion'),
                SizedBox(height: 6),
                Text(
                    'In 2008, ICpEP expanded its reach into academia by forming the ICpEP Student Edition (ICpEP.SE). Starting with 11 schools, ICpEP.SE has since grown to include over 68 schools nationwide.'),
                SizedBox(height: 10),
                Text('Regional Chapters'),
                SizedBox(height: 6),
                Text(
                    'In 2014, ICpEP expanded its structure by establishing regional chapters across the Philippines, each with its own ICpEP Student Edition (ICpEP.SE) counterpart. This expansion enabled the organization to better serve the diverse needs of computer engineering students and professionals in various regions, strengthening its nationwide reach.'),
                SizedBox(height: 10),
                Text('NCR Chapter'),
                SizedBox(height: 6),
                Text(
                    'The NCR Chapter has a strong presence and includes affiliations with several prominent institutions. These institutions actively participate in ICpEP activities, helping to foster a strong community of computer engineering students and professionals within the region.'),
                SizedBox(height: 12),
                Text('Official ICpEP NCR About Us: icpepncr.org/aboutus'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: _openOfficialPage,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Visit Official Page'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openAboutUs,
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sign out of this device',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'You can sign back in anytime. Your saved email/password (if Remember Me) will be kept.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    onPressed: () {
                      CustomDialogs.customOptionDialog(
                        context,
                        title: 'Logout',
                        content: 'Are you sure you want to logout?',
                        onYes: () async {
                          // Clear authentication data but preserve "Remember Me" credentials
                          final prefs = await SharedPreferences.getInstance();

                          // Save "Remember Me" credentials before clearing
                          final String? savedEmail = prefs.getString('saved_email');
                          final String? savedPassword = prefs.getString('saved_password');

                          // Clear all preferences
                          await prefs.clear();

                          // Restore "Remember Me" credentials if they existed
                          if (savedEmail != null && savedPassword != null) {
                            await prefs.setString('saved_email', savedEmail);
                            await prefs.setString('saved_password', savedPassword);
                          }

                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
