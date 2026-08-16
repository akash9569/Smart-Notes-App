import re

with open('lib/widgets/sidebar.dart', 'r') as f:
    content = f.read()

# Fix the duplicate context in function definitions
content = content.replace("Widget _buildSmallActionButton(BuildContext context, BuildContext context, ", "Widget _buildSmallActionButton(BuildContext context, ")
content = content.replace("Widget _buildNavItem(BuildContext context, BuildContext context, ", "Widget _buildNavItem(BuildContext context, ")

# Fix the call sites that got duplicate contexts or wrong types
# The sed was: s/_buildSmallActionButton(/_buildSmallActionButton(context, /g
# But it also matched the function definition!
# We just replaced the definition above.
content = content.replace("_buildSmallActionButton(context, context, ", "_buildSmallActionButton(context, ")
content = content.replace("_buildNavItem(context, context, ", "_buildNavItem(context, ")

with open('lib/widgets/sidebar.dart', 'w') as f:
    f.write(content)

