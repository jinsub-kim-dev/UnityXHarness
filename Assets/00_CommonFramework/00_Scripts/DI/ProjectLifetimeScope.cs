using O2un.Data;
using O2un.Input;
using O2un.Manager;
using VContainer;
using VContainer.Unity;

namespace O2un.DI
{
    public class ProjectLifetimeScope : LifetimeScope
    {
        protected override void Configure(IContainerBuilder builder)
        {
            builder.RegisterEntryPoint<InputManager>();
            builder.Register<DataProvider>(Lifetime.Singleton).AsImplementedInterfaces().AsSelf();
            builder.Register<OptionManager>(Lifetime.Singleton).AsImplementedInterfaces().AsSelf();
            builder.Register<SceneManager>(Lifetime.Singleton).AsImplementedInterfaces().AsSelf();

            builder.RegisterEntryPoint<ProjectBootStrap>();
        }
    }
}