module Sections
  class PanelListSection
    DEFAULT_STATUS_CLASSES = {
      'panel-success' => 'success',
      'panel-danger'  => 'danger',
      'panel-warning' => 'warning',
    }.freeze

    DEFAULT_ICON_TRANSLATIONS = {
      'icon-success' => 'success',
      'icon-warning' => 'warning',
      'icon-danger' => 'failed',
    }.freeze

    def initialize(
      panel_element,
      item_config: {},
      status_classes: DEFAULT_STATUS_CLASSES,
      icon_translations: DEFAULT_ICON_TRANSLATIONS
    )
      @panel_element = panel_element
      @item_config = item_config
      @status_classes = status_classes
      @icon_translations = icon_translations
    end

    def status
      classes = panel_element[:class].split
      status_class = (classes & status_classes.keys).first
      status_classes.fetch(status_class)
    end

    def items
      item_elements.map { |item_element|
        item_data = item_config.map { |name, selector|
          [name, cell_text(item_element.first(selector))]
        }.to_h

        item_data.values.all?(&:present?) ? item_data : nil
      }.compact
    end

    private

    attr_reader :panel_element, :item_config, :status_classes, :icon_translations

    def cell_text(cell_element)
      return unless cell_element

      icon = icon_element(cell_element)
      return icon_translation_for(icon) if icon

      cell_element.text
    end

    def icon_element(cell_element)
      classes = cell_element['class'].split(' ')
      if classes.include?('glyphicon')
        cell_element
      else
        cell_element.first('.glyphicon')
      end
    end

    def icon_translation_for(icon_element)
      icon_element['class'].split(' ').map { |klass|
        icon_translations[klass]
      }.compact.first
    end

    def item_elements
      list = panel_body.all('li')
      list.any? ? list : [panel_body]
    end

    def panel_body
      panel_element.first('.panel-heading ~ *')
    end
  end
end
