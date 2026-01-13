import 'package:flutter/material.dart';


class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20),),
                filled: true,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),),
                focusColor: Colors.white,
                fillColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.filter_list, size: 20),
              label: Text("Filters"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black87),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
