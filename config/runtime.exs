import Config

config(:unsplash_proxy, UnsplashProxy.Server, port: Box.Config.get("PORT", default: "4000"))

config(:unsplash_proxy, UnsplashProxy.Handler,
  unsplash_api_key: Box.Config.get!("UNSPLASH_API_KEY")
)
