module TestcasesHelper

  def testcase_status_badge(testcase)
    content_tag :span, testcase.status_label, class: "badge #{testcase.status_css_class}"
  end

  def testcase_status_select(form, selected = nil)
    form.select :status,
                Testcase.status_options,
                { selected: selected },
                { class: 'form-control' }
  end

  def format_testcase_field(text)
    return '' if text.blank?
    simple_format(h(text))
  end

  def testcase_summary_widget(summary)
    render partial: 'testcases/summary_widget', locals: { summary: summary }
  end
end
