@login_required
def variable_list(request):
    role = getRole(request)
    crear = (role == 'Gerencia Campus')
    if role == "Gerencia Campus":
        variables = get_variables()
        context = {
            'variable_list': variables,
            'crear': crear
        }
        return render(request, 'Variable/variables.html', context)
    else:
        return HttpResponse("Unauthorized User")


<div class="content">
  <div class="">
    <div class="page-header-title">
      <h4 class="page-title">Variables</h4>
      <div style="text-align:right;">
        <% if crear %>
          <button type="button" class="btn btn-success waves-effect waves-light"
            onClick="window.location.href='/variablecreate'" style="text-align:center;">
            +
          </button>
        <% endif %>
      </div>
    </div>
  </div>
</div>

<br>
