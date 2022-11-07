import 'dart:io';

import 'package:meta/meta.dart';

import 'package:iris/src/middleware.dart';
import './request.dart';

import './response.dart';

abstract class _RouteRoot {
  List<Middleware> middleware = [];
  _RouteRoot(this.middleware);
}

class Route<T extends Response> extends _RouteRoot {
  String name;

  @nonVirtual
  void handleRoute({
    required HttpRequest request,
    required List<Middleware> pathMiddleware,
    required HttpResponse response,
    Request req(request),
    Response res(response),
  }) {
    bool allcalled = true;
    for (Middleware mw in pathMiddleware) {
      // TODO: mw(req, res) -> if res is sent then end connection
      // DOUBT: if OK is set true by previous middleware or any one. 
      // res.ok = false;
      mw(req, res);
      if(res.ok == false){
        allcalled = false;
        break;
      }
    }
    // TODO: based on HTTP verb, run handler method    
    if(allcalled){
      switch (req.method){
        case "GET": { 
          get(req, res)
        } 
        break; 
        case "HEAD": { 
          head(req, res) 
        } 
        break;
        case "POST": { 
          post(req, res) 
        } 
        break;
        case "PUT": { 
          put(req, res); 
        } 
        break;
        case "PATCH": { 
          patch(req, res);
        } 
        break;
        case "DELETE": { 
          delete(req, res);
        } 
        break;
        case "CONNECT": { 
          connect(req, res);
        } 
        break;
        case "OPTIONS": { 
          options(req, res);
        } 
        break;
        case "TRACE": { 
          trace(req, res);
        } 
        break; 
        default: { 
            //statements;  
        }
        break; // reduntant ig
      }
    }
  
  }

  // TODO: send default error messages in handlers
  void get(Request req, Response res) {}
  void head(Request req, Response res) {}
  void post(Request req, Response res) {}
  void put(Request req, Response res) {}
  void patch(Request req, Response res) {}
  void delete(Request req, Response res) {}
  void connect(Request req, Response res) {}
  void options(Request req, Response res) {}
  void trace(Request req, Response res) {}
  Route(this.name, {List<Middleware> middleware = const []})
      : super(middleware);
}

class RouteTable extends _RouteRoot {
  Map<String, _RouteRoot> routes;
  RouteTable({required this.routes, List<Middleware> middleware = const []})
      : super(middleware);
  // TODO: validate routes so "/" endpoints cannot be set as RouteTables.
  static Route findRoute({
    required List<String> pathSegments,
    required RouteTable routeTable,
    int idx = 0,
    required List<Middleware> pathMiddleware,
  }) {
    if (idx == pathSegments.length) {
      if (routeTable.routes.containsKey('/')) {
        pathMiddleware.addAll(routeTable.routes['/']!.middleware);
        return routeTable.routes['/'] as Route;
      } else if (routeTable.routes.containsKey('*')) {
        pathMiddleware.addAll(routeTable.routes['*']!.middleware);
        return routeTable.routes['*'] as Route;
      }
      return Route('404: Not Found');
    }
    String path = pathSegments[idx];
    if (routeTable.routes.containsKey(path)) {
      pathMiddleware.addAll(routeTable.routes[path]!.middleware);
      if (routeTable.routes[path] is Route) {
        return routeTable.routes[path] as Route;
      }
      return findRoute(
        pathSegments: pathSegments,
        routeTable: routeTable.routes[path] as RouteTable,
        idx: idx + 1,
        pathMiddleware: pathMiddleware,
      );
    } else if (routeTable.routes.containsKey('*')) {
      pathMiddleware.addAll(routeTable.routes['*']!.middleware);
      return routeTable.routes['*'] as Route;
    }
    return Route('404: Not Found');
  }
}
