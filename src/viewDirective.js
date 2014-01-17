
$ViewDirective.$inject = ['$state', '$compile', '$controller', '$injector', '$anchorScroll'];
function $ViewDirective(   $state,   $compile,   $controller,   $injector,   $anchorScroll) {
  var $animator = $injector.has('$animator') ? $injector.get('$animator') : false;
  var viewIsUpdating = false;

  var directive = {
    restrict: 'ECA',
    terminal: true,
    priority: 1000,
    transclude: true,
    compile: function (element, attr, transclude) {
      return function(scope, element, attr) {
        var viewScope, viewLocals,
            name = attr[directive.name] || attr.name || '',
            onloadExp = attr.onload || '',
            animate = $animator && $animator(scope, attr),
            initialView = transclude(scope);

        // Put back the compiled initial view
        element.append(initialView);

        // Find the details of the parent view directive (if any) and use it
        // to derive our own qualified view name, then hang our own details
        // off the DOM so child directives can find it.
        var parent = scope.parent ? scope.parent.name : ''
        if (name.indexOf('@') < 0) name  = name + '@' + parent
        var view = { name: name, state: null };
        element.data('$uiView', view);

        var eventHook = function() {
          if (viewIsUpdating) return;
          viewIsUpdating = true;

          try { updateView(true); } catch (e) {
            viewIsUpdating = false;
            throw e;
          }
          viewIsUpdating = false;
        };

        scope.$on('$stateChangeSuccess', eventHook);
        scope.$on('$viewContentLoading', eventHook);
        updateView(false);

        function updateView(doAnimate) {
          var locals = $state.$current && $state.$current.locals[name];
          if (locals === viewLocals) return; // nothing to do

          // Remove existing content

          // Destroy previous view scope
          if (viewScope) {
            viewScope.$destroy();
            viewScope = null;
          }

          if (!locals) {
            viewLocals = null;
            view.state = null;

            // Restore the initial view
          }

          viewLocals = locals;
          view.state = locals.$$state;

          var link = $compile(locals.$template)
          viewScope = scope.$new();
          viewScope.parent = locals.$$state

          if (locals.$$controller) {
            locals.$scope = viewScope;
            var controller = $controller(locals.$$controller, locals);
            element.children().data('$ngControllerController', controller);
          }
          link(viewScope, function(clonedElement, scope) {
                setTimeout(function() {
                    scope.$apply(function() {
                        element.children().remove()
                        element.append(clonedElement)
                        scope.$emit('$viewContentLoaded');
                        if (onloadExp) viewScope.$eval(onloadExp);
                        // TODO: This seems strange, shouldn't $anchorScroll listen for $viewContentLoaded if necessary?
                        // $anchorScroll might listen on event...
                        $anchorScroll();
                    })
                }, 0)
          });

        }
      };
    }
  };
  return directive;
}
angular.module('ui.router.state').directive('uiView', $ViewDirective);
