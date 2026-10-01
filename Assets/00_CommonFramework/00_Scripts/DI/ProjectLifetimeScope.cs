using O2un.Input;
using VContainer;
using VContainer.Unity;

namespace O2un.DI
{
    public class ProjectLifetimeScope : LifetimeScope
    {
        protected override void Configure(IContainerBuilder builder)
        {
            builder.RegisterEntryPoint<InputManager>();
        }
    }
}