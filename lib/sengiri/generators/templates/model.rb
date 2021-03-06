<% module_namespacing do -%>
class <%= class_name %> < <%= parent_class_name.classify %>
  sharding_group :<%= group %>
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %><%= ', polymorphic: true' if attribute.polymorphic? %>
<% end -%>
<% if attributes.any?(&:password_digest?) -%>
  has_secure_password
<% end -%>
end
<% end -%>
