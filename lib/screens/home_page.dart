// import 'package:countdowns/router.dart';
// import 'package:countdowns/screens/add_countdown_page.dart';
// import 'package:countdowns/screens/countdown_page.dart';
// import 'package:countdowns/screens/settings_page.dart';
// import 'package:countdowns/utilities/countdowns_provider.dart';
// import 'package:countdowns/widgets/countdown_card.dart';
// import 'package:countdowns/widgets/countdown_card_empty.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import 'package:provider/src/provider.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({Key? key, required this.title}) : super(key: key);

//   final String title;

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//         elevation: 0,
//         actions: [
//           Visibility(
//             visible: context.read<CountdownsProvider>().events.isNotEmpty,
//             child: IconButton(
//               iconSize: 28,
//               icon: const Icon(
//                 Icons.add_rounded,
//               ),
//               onPressed: () => router.go('/add'),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(Icons.settings_rounded),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   fullscreenDialog: true,
//                   builder: (context) {
//                     return const SettingsPage();
//                   },
//                 ),
//               );
//             },
//           ),
//         ],
//       ),

//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
//         child: context.watch<CountdownsProvider>().events.isNotEmpty
//             ? ListView.builder(
//                 itemCount: context.watch<CountdownsProvider>().events.length,
//                 itemBuilder: (BuildContext context, int index) {
//                   return GestureDetector(
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => CountdownPage(
//                           countdownEvent:
//                               context.watch<CountdownsProvider>().events[index],
//                         ),
//                       ),
//                     ),
//                     child: CountdownCard(
//                       countdownEvent:
//                           context.read<CountdownsProvider>().events[index],
//                     ),
//                   );
//                 },
//               )
//             : ListView(
//                 children: [
//                   GestureDetector(
//                       onTap: () => Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) {
//                                 return const AddCountdownPage();
//                               },
//                             ),
//                           ),
//                       child: const CountdownCardEmpty())
//                 ],
//               ),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
