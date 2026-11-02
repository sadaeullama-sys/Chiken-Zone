import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ChickenZoneApp());

const red = Color(0xFFC90016);
const navy = Color(0xFF12356B);

class ChickenZoneApp extends StatelessWidget {
  const ChickenZoneApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TU Chicken Zone',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: red),
      appBarTheme: const AppBarTheme(backgroundColor: red, foregroundColor: Colors.white),
      scaffoldBackgroundColor: const Color(0xFFF5F6F8)),
    home: const HomePage());
}

class Entry {
  String title, date, detail;
  double amount;
  Entry(this.title, this.date, this.detail, this.amount);
  Map<String,dynamic> toJson()=>{'title':title,'date':date,'detail':detail,'amount':amount};
  factory Entry.fromJson(Map<String,dynamic> j)=>Entry(j['title'],j['date'],j['detail'],(j['amount'] as num).toDouble());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState()=>_HomePageState();
}
class _HomePageState extends State<HomePage> {
  int tab=0;
  List<Entry> entries=[];
  String shop='Chicken Zone';
  @override void initState(){super.initState();load();}
  Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    final raw=p.getString('entries') ?? '[]';
    setState(()=>entries=(jsonDecode(raw) as List).map((e)=>Entry.fromJson(e)).toList());
    shop=p.getString('shop')??'Chicken Zone';
  }
  Future<void> save() async {final p=await SharedPreferences.getInstance(); await p.setString('entries',jsonEncode(entries.map((e)=>e.toJson()).toList()));}
  double sum(String type)=>entries.where((e)=>e.title==type).fold(0,(a,e)=>a+e.amount);
  void add(String type) async {
    final amount=TextEditingController(), detail=TextEditingController();
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(type),content:Column(mainAxisSize:MainAxisSize.min,children:[
      TextField(controller:detail,decoration:const InputDecoration(labelText:'Details / وزن یا نوٹ')),
      TextField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Amount (Rs.)')),
    ]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel')),FilledButton(onPressed:(){
      final n=double.tryParse(amount.text)??0;
      if(n>0){setState(()=>entries.insert(0,Entry(type,DateTime.now().toString().substring(0,10),detail.text,n)));save();}
      Navigator.pop(ctx);
    },child:const Text('Save'))]));
  }
  @override Widget build(BuildContext context){
    final pages=[dashboard(),ledger(),customers(),reports(),settings()];
    return Scaffold(appBar:AppBar(title:Text('🐓 $shop'),leading:const Icon(Icons.menu),),
      body:pages[tab],bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const[
        NavigationDestination(icon:Icon(Icons.home),label:'Home'),
        NavigationDestination(icon:Icon(Icons.scale),label:'Mall'),
        NavigationDestination(icon:Icon(Icons.people),label:'Customers'),
        NavigationDestination(icon:Icon(Icons.bar_chart),label:'Reports'),
        NavigationDestination(icon:Icon(Icons.settings),label:'More'),
      ]));
  }
  Widget dashboard()=>ListView(padding:const EdgeInsets.all(12),children:[
    Container(height:145,decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),gradient:const LinearGradient(colors:[red,Color(0xFF7D0010)])),
      child:const Center(child:Text('TU CHICKEN ZONE\\nPoultry Business Solution',textAlign:TextAlign.center,style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.bold)))),
    const SizedBox(height:12),
    GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.45,crossAxisSpacing:9,mainAxisSpacing:9,children:[
      metric('Total Mall', '— Kg',Icons.scale,navy), metric('Mall Ki Qeemat',money(sum('Purchase')),Icons.currency_rupee,red),
      metric('Mall Mein Kami','— Kg',Icons.remove_circle,Colors.orange),metric('Total Purchase',money(sum('Purchase')),Icons.shopping_cart,Colors.green),
      metric('Total Sale',money(sum('Sale')),Icons.point_of_sale,navy),metric('Customer Udhaar',money(sum('Udhaar')),Icons.people,Colors.purple),
      metric('Today Profit',money(sum('Sale')-sum('Purchase')),Icons.trending_up,Colors.green),metric('Expenses',money(sum('Expense')),Icons.money_off,red),
    ]),
    const SizedBox(height:14),const Text('Quick Actions',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    Wrap(spacing:8,runSpacing:8,children:['Purchase','Sale','Udhaar','Expense'].map((x)=>FilledButton.icon(onPressed:()=>add(x),icon:const Icon(Icons.add),label:Text(x))).toList()),
    const SizedBox(height:12),const Text('Recent Records',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
    ...entries.take(6).map((e)=>ListTile(leading:const Icon(Icons.receipt_long,color:red),title:Text(e.title),subtitle:Text('${e.date} • ${e.detail}'),trailing:Text(money(e.amount)))),
  ]);
  Widget metric(String title,String value,IconData icon,Color color)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(icon,color:color,size:28),Text(title,style:const TextStyle(fontWeight:FontWeight.w600)),Text(value,style:TextStyle(color:color,fontSize:18,fontWeight:FontWeight.bold))])));
  Widget ledger()=>ListView(padding:const EdgeInsets.all(12),children:[
    const Text('Mall & Business Ledger',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
    Wrap(spacing:8,children:['Purchase','Sale','Expense'].map((x)=>FilledButton(onPressed:()=>add(x),child:Text('Add $x'))).toList()),
    ...entries.map((e)=>Card(child:ListTile(title:Text(e.title),subtitle:Text('${e.date} | ${e.detail}'),trailing:Text(money(e.amount))))),
  ]);
  Widget customers()=>CustomerPage(entries:entries,onAdd:()=>add('Udhaar'));
  Widget reports()=>ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Reports',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    reportRow('Total Sale',sum('Sale')),reportRow('Total Purchase',sum('Purchase')),reportRow('Expenses',sum('Expense')),
    reportRow('Net Profit / Loss',sum('Sale')-sum('Purchase')-sum('Expense')),
    const SizedBox(height:12),const Text('Records are stored locally on this device. Export/backup options can be added in the next version.')
  ]);
  Widget reportRow(String label,double value)=>Card(child:ListTile(title:Text(label),trailing:Text(money(value),style:const TextStyle(fontWeight:FontWeight.bold))));
  Widget settings()=>SettingsPage(initial:shop,onSave:(s)async{final p=await SharedPreferences.getInstance();await p.setString('shop',s);setState(()=>shop=s);});
  String money(double n)=>'Rs. ${n.toStringAsFixed(0)}';
}

class CustomerPage extends StatelessWidget{
  final List<Entry> entries; final VoidCallback onAdd;
  const CustomerPage({super.key,required this.entries,required this.onAdd});
  @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(12),children:[
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Customers / کسٹمرز',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),FilledButton.icon(onPressed:onAdd,icon:const Icon(Icons.add),label:const Text('Udhaar'))]),
    const Text('Customer balances are represented by Udhaar entries in this starter build.'),
    ...entries.where((e)=>e.title=='Udhaar').map((e)=>Card(child:ListTile(leading:const Icon(Icons.person,color:navy),title:Text(e.detail.isEmpty?'Customer':e.detail),subtitle:Text(e.date),trailing:Text('Rs. ${e.amount.toStringAsFixed(0)}'))))
  ]);
}
class SettingsPage extends StatefulWidget{
 final String initial; final Future<void> Function(String) onSave;
 const SettingsPage({super.key,required this.initial,required this.onSave});
 @override State<SettingsPage> createState()=>_SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage>{
 late TextEditingController c;
 @override void initState(){super.initState();c=TextEditingController(text:widget.initial);}
 @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(16),children:[
  const Text('Shop Settings',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
  TextField(controller:c,decoration:const InputDecoration(labelText:'Shop Name')),
  const SizedBox(height:12),FilledButton(onPressed:()=>widget.onSave(c.text),child:const Text('Save Settings')),
  const SizedBox(height:20),const ListTile(leading:Icon(Icons.backup),title:Text('Backup & Restore'),subtitle:Text('Local data storage enabled')),
  const ListTile(leading:Icon(Icons.lock),title:Text('License Activation'),subtitle:Text('Demo / license flow will be configured in a later release')),
  const ListTile(leading:Icon(Icons.info),title:Text('About Developer'),subtitle:Text('TU Chicken Zone Management System')),
 ]);
}
