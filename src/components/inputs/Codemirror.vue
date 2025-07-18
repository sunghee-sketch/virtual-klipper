<template>
    <div class="vue-codemirror">
        <div ref="editor" v-observe-visibility="visibilityChanged"></div>
    </div>
</template>

<script lang="ts">
// Inspired by this repo: https://github.com/surmon-china/vue-codemirror

import { Component, Mixins, Prop, Ref, Watch } from 'vue-property-decorator'
import BaseMixin from '../mixins/base'
import ThemeMixin from '../mixins/theme'
import { basicSetup } from 'codemirror'
import { EditorView, keymap } from '@codemirror/view'
import { EditorState } from '@codemirror/state'
import { vscodeDark, vscodeLight } from '@uiw/codemirror-theme-vscode'
import { StreamLanguage } from '@codemirror/language'
import { klipper_config } from '@/plugins/StreamParserKlipperConfig'
import { gcode } from '@/plugins/StreamParserGcode'
import { indentWithTab } from '@codemirror/commands'
import { json } from '@codemirror/lang-json'
import { css } from '@codemirror/lang-css'
import { indentUnit } from '@codemirror/language'

@Component
export default class Codemirror extends Mixins(BaseMixin, ThemeMixin) {
    private content = ''
    private codemirror: null | EditorView = null
    private cminstance: null | EditorView = null

    @Ref('editor') editor!: HTMLElement

    @Prop({ required: false, default: '' })
    declare readonly code: string

    @Prop({ required: false, default: '' })
    declare value: string

    @Prop({ required: false, default: 'codemirror' })
    declare readonly name: string

    @Prop({ required: false, default: '' })
    declare readonly fileExtension: string

    @Watch('value')
    valueChanged(newVal: string) {
        const cm_value = this.cminstance?.state?.doc.toString()
        if (newVal !== cm_value) {
            this.setCmValue(newVal)
        }
    }

    mounted(): void {
        this.initialize()
    }

    beforeDestroy() {
        this.destroy()
    }

    destroy() {
        this.cminstance?.destroy()
    }

    initialize() {
        this.codemirror = new EditorView({
            parent: this.editor,
        })
        this.cminstance = this.codemirror

        this.$nextTick(() => {
            this.setCmValue(this.code || this.value || this.content)

            this.$emit('ready', this.codemirror)
        })
    }

    setCmValue(content: string) {
        this.cminstance?.setState(EditorState.create({ doc: content, extensions: this.cmExtensions }))
    }

    get cmExtensions() {
        const extensions = [
            EditorView.theme({}, { dark: this.themeMode === 'dark' }),
            basicSetup,
            this.vscodeTheme,
            indentUnit.of(' '.repeat(this.tabSize)),
            keymap.of([indentWithTab]),
            EditorView.updateListener.of((update) => {
                if (update.selectionSet) {
                    const line = this.cminstance?.state?.doc.lineAt(this.cminstance?.state?.selection.main.head).number
                    this.$emit('lineChange', line)
                }
                this.content = update.state?.doc.toString()
                if (this.$emit) {
                    this.$emit('input', this.content)
                }
            }),
        ]

        if (['cfg', 'conf'].includes(this.fileExtension)) extensions.push(StreamLanguage.define(klipper_config))
        else if (['gcode'].includes(this.fileExtension)) extensions.push(StreamLanguage.define(gcode))
        else if (['json'].includes(this.fileExtension)) extensions.push(json())
        else if (['css', 'scss', 'sass'].includes(this.fileExtension)) extensions.push(css())

        return extensions
    }

    visibilityChanged(isVisible: boolean) {
        if (isVisible) this.cminstance?.focus()
    }

    get tabSize() {
        return this.$store.state.gui.editor.tabSize || 2
    }

    get vscodeTheme() {
        return this.themeMode === 'dark' ? vscodeDark : vscodeLight
    }

    gotoLine(line: number) {
        const l = this.cminstance?.state?.doc.line(line)
        if (!l) return

        this.cminstance?.dispatch({
            selection: { head: l.from, anchor: l.to },
            scrollIntoView: true,
        })
    }
}
</script>
