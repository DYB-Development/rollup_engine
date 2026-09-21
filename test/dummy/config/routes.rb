Rails.application.routes.draw do
  mount RollupEngine::Engine => "/rollup_engine"
end
