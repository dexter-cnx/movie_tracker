import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/features/movies/presentation/movie_providers.dart';
import 'package:popcorn_movie_tracker/features/watchlist/presentation/watchlist_controller.dart';
import 'package:popcorn_movie_tracker/shared/widgets/clay_widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final lang = apiLanguage(context.locale.languageCode);
    final trending = ref.watch(trendingProvider(lang));
    final watchlist = ref.watch(watchlistControllerProvider);
    return SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,18,20,120),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('welcome'.tr(namedArgs:{'name':'Dexter'}),style:Theme.of(context).textTheme.headlineLarge),const SizedBox(height:5),Text('hotToday'.tr(),style:Theme.of(context).textTheme.bodyMedium)])),const ClayIconButton(icon:Icons.notifications_none_rounded),const SizedBox(width:10),const ClayIconButton(icon:Icons.calendar_month_rounded)]),
      const SizedBox(height:24),
      Container(height:54,padding:const EdgeInsets.symmetric(horizontal:16),decoration:BoxDecoration(color:AppColors.card,borderRadius:BorderRadius.circular(27),border:Border.all(color:Colors.white.withValues(alpha: .04))),child:Row(children:[const Icon(Icons.search_rounded),const SizedBox(width:12),Expanded(child:Text('searchHint'.tr(),style:Theme.of(context).textTheme.bodyMedium)),const ClayIconButton(icon:Icons.tune_rounded)])),
      const SizedBox(height:22),
      ClayCard(child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('watchStats'.tr(),style:Theme.of(context).textTheme.titleLarge)),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:AppColors.green.withValues(alpha: .12),borderRadius:BorderRadius.circular(14)),child:const Text('+3.45%',style:TextStyle(color:AppColors.green,fontWeight:FontWeight.w800,fontSize:12)))]),const SizedBox(height:18),SizedBox(height:90,child:BarChart(BarChartData(gridData:const FlGridData(show:false),titlesData:const FlTitlesData(show:false),borderData:FlBorderData(show:false),barGroups:List.generate(7,(i)=>BarChartGroupData(x:i,barRods:[BarChartRodData(toY:[3,5,4,7,6,8,5][i].toDouble(),width:10,borderRadius:BorderRadius.circular(4),color:i==5?AppColors.orange:AppColors.elevated)]))))),const SizedBox(height:15),FilledButton(onPressed:(){},style:FilledButton.styleFrom(backgroundColor:AppColors.button,foregroundColor:AppColors.onButton,padding:const EdgeInsets.symmetric(horizontal:20,vertical:13),shape:const StadiumBorder()),child:Text('checkNow'.tr()))])),const SizedBox(width:12)])),
      const SizedBox(height:28),_sectionHeader(context,'trendingNow'.tr()),const SizedBox(height:14),
      SizedBox(height:285,child:trending.when(data:(movies)=>ListView.separated(scrollDirection:Axis.horizontal,itemCount:movies.take(6).length,separatorBuilder:(_,__)=>const SizedBox(width:14),itemBuilder:(context,i){final m=movies[i];return GestureDetector(onTap:()=>context.push('/movie/${m.id}'),child:SizedBox(width:165,child:ClayCard(padding:const EdgeInsets.all(10),radius:25,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Poster(path:m.posterPath,width:145,height:175,title:m.title),const SizedBox(height:10),Row(children:[Expanded(child:Text(m.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800))),Text(m.voteAverage.toStringAsFixed(1),style:const TextStyle(fontWeight:FontWeight.w900))]),const SizedBox(height:4),Text(m.genres.isEmpty?'movie'.tr():m.genres.first,style:Theme.of(context).textTheme.bodyMedium),const Spacer(),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:(m.popularity/100).clamp(0,1),minHeight:5,backgroundColor:AppColors.elevated,color:AppColors.orange))]))));}),loading:()=>const Center(child:CircularProgressIndicator()),error:(_,__)=>const SizedBox.shrink())),
      const SizedBox(height:28),_sectionHeader(context,'myWatchlist'.tr(),action:TextButton(onPressed:()=>context.go('/watchlist'),child:Text('seeAll'.tr()))),const SizedBox(height:10),
      if(watchlist.isEmpty)...List.generate(3,(i)=>_watchRow(context,['Dune: Part Two','Inside Out 2','The Wild Robot'][i],['upcoming'.tr(),'watched'.tr(),'60% ${'watched'.tr()}'][i])) else ...watchlist.take(4).map((e)=>_watchRow(context,e.title,e.status.name.tr())),
    ])));
  }
  Widget _sectionHeader(BuildContext c,String title,{Widget? action})=> Row(children:[Expanded(child:Text(title,style:Theme.of(c).textTheme.titleLarge)), if (action != null) action]);
  Widget _watchRow(BuildContext c,String title,String status)=>Padding(padding:const EdgeInsets.only(bottom:12),child:ClayCard(padding:const EdgeInsets.all(12),radius:22,child:Row(children:[Container(width:52,height:52,decoration:BoxDecoration(color:AppColors.cardAlt,borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.movie_rounded)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(status,style:Theme.of(c).textTheme.bodyMedium)])),Text('${'today'.tr()}: 8:15pm',style:Theme.of(c).textTheme.bodyMedium)])));
}
