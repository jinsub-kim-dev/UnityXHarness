using System;
using System.Reflection;
using Newtonsoft.Json.Linq;
using UnityEngine;
using MCPForUnity.Editor.Helpers;
using MCPForUnity.Editor.Tools;

namespace Labinno.Editor
{
    [McpForUnityTool("gate3_run_test")]
    public static class Gate3TestTool
    {
        public class Parameters
        {
            [ToolParameter("Component type full name (e.g. Labinno.MyComponent)")]
            public string type_name { get; set; }

            [ToolParameter("Call Start() via reflection after component creation", Required = false)]
            public bool call_start { get; set; }

            [ToolParameter("Inject via VContainer LifetimeScope.Container", Required = false)]
            public bool inject { get; set; }

            [ToolParameter("Field names to verify are non-null after setup", Required = false)]
            public string[] check_non_null_fields { get; set; }
        }

        public static object HandleCommand(JObject @params)
        {
            var p = @params.ToObject<Parameters>();
            if (string.IsNullOrEmpty(p.type_name))
                return new ErrorResponse("type_name is required");

            Type componentType = ResolveType(p.type_name);
            if (componentType == null)
                return new SuccessResponse($"FAIL: Type '{p.type_name}' not found");
            if (!typeof(MonoBehaviour).IsAssignableFrom(componentType))
                return new SuccessResponse($"FAIL: '{p.type_name}' is not a MonoBehaviour");

            var go = new GameObject("__gate3_test__");
            try
            {
                var comp = go.AddComponent(componentType);

                if (p.inject)
                {
                    var injectResult = InjectVContainer(comp);
                    if (injectResult != null) return new SuccessResponse(injectResult);
                }

                if (p.call_start)
                {
                    var start = componentType.GetMethod("Start",
                        BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                    start?.Invoke(comp, null);
                }

                if (p.check_non_null_fields != null)
                {
                    foreach (var fieldName in p.check_non_null_fields)
                    {
                        var field = componentType.GetField(fieldName,
                            BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                        if (field == null)
                            return new SuccessResponse($"FAIL: Field '{fieldName}' not found on {p.type_name}");
                        if (field.GetValue(comp) == null)
                            return new SuccessResponse($"FAIL: Field '{fieldName}' is null after setup");
                    }
                }

                var tags = (p.inject ? "+VContainer" : "") + (p.call_start ? "+Start" : "");
                return new SuccessResponse($"PASS: {p.type_name}{tags} OK");
            }
            catch (Exception e)
            {
                return new SuccessResponse($"FAIL: Exception: {e.InnerException?.Message ?? e.Message}");
            }
            finally
            {
                UnityEngine.Object.DestroyImmediate(go);
            }
        }

        static string InjectVContainer(Component comp)
        {
            Type scopeType = ResolveType("VContainer.Unity.LifetimeScope");
            if (scopeType == null)
                return "FAIL: VContainer.Unity.LifetimeScope not found (VContainer not installed?)";

            var scope = UnityEngine.Object.FindFirstObjectByType(scopeType);
            if (scope == null)
                return "FAIL: No LifetimeScope found in scene (is play mode active?)";

            var containerProp = scopeType.GetProperty("Container");
            if (containerProp == null)
                return "FAIL: LifetimeScope.Container property not found";

            var container = containerProp.GetValue(scope);
            if (container == null)
                return "FAIL: Container is null";

            var injectMethod = container.GetType().GetMethod("Inject",
                new[] { typeof(object) });
            if (injectMethod == null)
                return "FAIL: IObjectResolver.Inject(object) not found";

            injectMethod.Invoke(container, new object[] { comp });
            return null;
        }

        static Type ResolveType(string name)
        {
            foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
            {
                var t = asm.GetType(name);
                if (t != null) return t;
            }
            return null;
        }
    }
}
