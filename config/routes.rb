# Plugin routes
# See: http://guides.rubyonrails.org/routing.html

# Test cases routes - scoped under issues
resources :issues do
  resources :testcases do
    collection do
      get :export_csv
      get :print_view
    end
  end
end
