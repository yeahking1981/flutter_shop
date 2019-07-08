import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../service/service_method.dart';
import 'dart:convert';
import '../model/category.dart';
import '../model/mallGoodsList.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../provide/childCategory.dart';
import '../provide/category_goods_list.dart';
import 'package:provide/provide.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('商品分类'),
      ),
      body: Container(
        child: Row(
          children: <Widget>[
            LeftCategoryNav(),
            Column(
              children: <Widget>[RightCategoryNav(), CategoryGoodsList()],
            )
          ],
        ),
      ),
    );
  }
}

// 左侧大类导航
class LeftCategoryNav extends StatefulWidget {
  @override
  _LeftCategoryNavState createState() => _LeftCategoryNavState();
}

class _LeftCategoryNavState extends State<LeftCategoryNav> {
  List list = [];
  var currentIndex = 0;

  @override
  void initState() {
    _getCategory();
    getGoodsList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ScreenUtil().setWidth(180),
      decoration: BoxDecoration(
          border: Border(right: BorderSide(width: 0.5, color: Colors.black12))),
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          return _leftInkWell(index);
        },
      ),
    );
  }

  Widget _leftInkWell(int index) {
    // bool isChoosed = false;
    // isChoosed = (index == listIndex)?true:false;
    return InkWell(
      onTap: () {
        setState(() {
          currentIndex = index;
        });
        var childList = list[index].bxMallSubDto;
        var categoryId = list[index].mallCategoryId;
        Provide.value<ChildCategory>(context).getChildCategory(childList);
        getGoodsList(categoryId: categoryId);
        // Provide.value<ChildCategory>(context).changeChildIndex(0);
      },
      child: Container(
        height: ScreenUtil().setHeight(100),
        padding: EdgeInsets.only(left: 10.0, top: 20.0),
        decoration: BoxDecoration(
            color: (currentIndex == index)
                ? Color.fromRGBO(236, 236, 236, 1.0)
                : Colors.white,
            border:
                Border(bottom: BorderSide(width: 0.5, color: Colors.black12))),
        child: Text(
          list[index].mallCategoryName,
          style: TextStyle(fontSize: ScreenUtil().setSp(28)),
        ),
      ),
    );
  }

  _getCategory() async {
    await getCategoryPageContent().then((val) {
      var data = json.decode(val.toString());
      CategoryModel category = CategoryModel.fromJson(data);
      // list.data.forEach((item) => print(item.mallCategoryName));
      setState(() {
        list = category.data;
      });
      Provide.value<ChildCategory>(context)
          .getChildCategory(category.data[0].bxMallSubDto);
      // return category.data;
    });
  }

  void getGoodsList({String categoryId}) async {
    var formData = {
      'categoryId': categoryId == null ? '4' : categoryId,
      'CategorySubId': '',
      'page': 1
    };
    await getMallGoods(formData).then((val) {
      var data = json.decode(val.toString());
      MallGoodsListModel goodsList = MallGoodsListModel.fromJson(data);
      // print('商品列表》》》》》》》${goodsList.data[0].goodsName}');

      // List<Map> newGoodsList = (data['data'] as List).cast();
      // setState(() {
      //   goodsList.addAll(newGoodsList);
      // });
      Provide.value<CategoryGoodsListProvide>(context)
          .changeGoodsList(goodsList.data);
    });
  }
}

class RightCategoryNav extends StatefulWidget {
  @override
  _RightCategoryNavState createState() => _RightCategoryNavState();
}

//小类右侧导航
class _RightCategoryNavState extends State<RightCategoryNav> {
  // List list = ['名酒', '宝丰', '北京二锅头', '舍得', '五粮液', '茅台'];

  @override
  Widget build(BuildContext context) {
    return Provide<ChildCategory>(
      builder: (context, child, childCategory) {
        return Container(
          height: ScreenUtil().setHeight(80),
          width: ScreenUtil().setWidth(570.0),
          decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(width: 0.5, color: Colors.black12)),
              color: Colors.white),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: childCategory.childCategoryList.length,
            itemBuilder: (context, index) {
              return _rightInkWell(
                  childCategory.childCategoryList[index], index);
            },
          ),
        );
      },
    );
  }

  Widget _rightInkWell(BxMallSubDto item, index) {
    return InkWell(
      onTap: () {
        Provide.value<ChildCategory>(context).changeChildIndex(index);
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(5.0, 10.0, 10.0, 10.0),
        child: Text(
          item.mallSubName,
          style: TextStyle(
              fontSize: ScreenUtil().setSp(28),
              color: Provide.value<ChildCategory>(context).childIndex == index
                  ? Colors.pink
                  : Colors.black),
        ),
      ),
    );
  }
}

// 商品列表，可以上拉加载
class CategoryGoodsList extends StatefulWidget {
  @override
  _CategoryGoodsListState createState() => _CategoryGoodsListState();
}

class _CategoryGoodsListState extends State<CategoryGoodsList> {
  int page = 1;
  GlobalKey<RefreshFooterState> _footerkey =
      new GlobalKey<RefreshFooterState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Provide<CategoryGoodsListProvide>(
      builder: (context, child, data) {
        return Expanded(
          child: Container(
              margin: EdgeInsets.only(top: 2.0),
              width: ScreenUtil().setWidth(570),
              // height: ScreenUtil().setHeight(1000),
              // margin: EdgeInsets.only(left: 2.5),
              child: ListView(
                children: <Widget>[_wrapList(data.goodsList)],
                // scrollDirection: Axis.vertical,
              )),
        );
      },
    );
  }

  Widget _wrapList(List<MallGoodsListData> list) {
    if (list.length != 0) {
      List<Widget> listWidget = list.map((val) {
        return InkWell(
          onTap: () {},
          child: Container(
            width: ScreenUtil().setWidth(280),
            color: Colors.white,
            padding: EdgeInsets.all(5.0),
            margin: EdgeInsets.only(bottom: 3.0),
            child: Column(
              children: <Widget>[
                Image.network(
                  '${val.image}',
                  width: ScreenUtil().setWidth(280),
                ),
                Text(
                  '${val.goodsName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.pink, fontSize: ScreenUtil().setSp(22)),
                ),
                Row(
                  children: <Widget>[
                    Text(
                      '￥${val.oriPrice}',
                      style: TextStyle(
                          color: Colors.black26,
                          decoration: TextDecoration.lineThrough,
                          fontSize: ScreenUtil().setSp(22)),
                    ),
                    Text(
                      '￥${val.presentPrice}',
                      style: TextStyle(fontSize: ScreenUtil().setSp(22)),
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                )
              ],
            ),
          ),
        );
      }).toList();
      return Wrap(
        spacing: 2,
        children: listWidget,
      );
    } else {
      return Text('该分类下暂无产品');
    }
  }

  // Widget _itemImage(index) {
  //   return Container(
  //     child: Image.network(goodsList[index].image),
  //   );
  // }
}
