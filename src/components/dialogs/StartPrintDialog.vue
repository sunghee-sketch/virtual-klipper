<template>
    <v-dialog
        v-model="bool"
        :max-width="400"
        content-class="overflow-x-hidden"
        @click:outside="closeDialog"
        @keydown.esc="closeDialog">
        <v-card>
            <div v-if="bigThumbnailUrl" class="d-flex align-center justify-center" style="min-height: 200px">
                <v-img
                    :src="bigThumbnailUrl"
                    :max-width="maxThumbnailWidth"
                    class="d-inline-block"
                    :style="bigThumbnailStyle" />
            </div>
            <v-card-title class="text-h5">{{ $t('Dialogs.StartPrint.Headline') }}</v-card-title>
            <v-card-text class="pb-0">
                <p class="body-2">
                    {{ question }}
                </p>
            </v-card-text>
            <start-print-dialog-spoolman v-if="moonrakerComponents.includes('spoolman')" :file="file" />
            <template v-if="moonrakerComponents.includes('timelapse')">
                <v-divider v-if="!moonrakerComponents.includes('spoolman')" class="mt-3 mb-2" />
                <v-card-text class="py-0">
                    <settings-row :title="$t('Dialogs.StartPrint.Timelapse')">
                        <v-switch v-model="timelapseEnabled" hide-details class="mt-0" />
                    </settings-row>
                </v-card-text>
                <v-divider class="mt-2 mb-0" />
            </template>
            <v-card-actions>
                <v-spacer />
                <v-btn text @click="closeDialog">{{ $t('Dialogs.StartPrint.Cancel') }}</v-btn>
                <v-btn
                    color="primary"
                    text
                    :disabled="printerIsPrinting || !klipperReadyForGui"
                    @click="startPrint(file.filename)">
                    {{ $t('Dialogs.StartPrint.Print') }}
                </v-btn>
            </v-card-actions>
        </v-card>
    </v-dialog>
</template>

<script lang="ts">
import { Component, Mixins, Prop } from 'vue-property-decorator'
import BaseMixin from '@/components/mixins/base'
import { FileStateGcodefile } from '@/store/files/types'
import SettingsRow from '@/components/settings/SettingsRow.vue'
import { mdiPrinter3d } from '@mdi/js'
import { ServerSpoolmanStateSpool } from '@/store/server/spoolman/types'
import { defaultBigThumbnailBackground, thumbnailBigMin } from '@/store/variables'

@Component({
    components: {
        SettingsRow,
    },
})
export default class StartPrintDialog extends Mixins(BaseMixin) {
    mdiPrinter3d = mdiPrinter3d

    @Prop({ required: true, default: false })
    declare readonly bool: boolean

    @Prop({ required: true, default: '' })
    declare readonly currentPath: string

    @Prop({ required: true })
    declare file: FileStateGcodefile

    get timelapseEnabled() {
        return this.$store.state.server.timelapse?.settings?.enabled ?? false
    }

    set timelapseEnabled(newVal) {
        this.$socket.emit(
            'machine.timelapse.post_settings',
            { enabled: newVal },
            { action: 'server/timelapse/initSettings' }
        )
    }

    get bigThumbnailBackground() {
        return this.$store.state.gui.uiSettings.bigThumbnailBackground ?? defaultBigThumbnailBackground
    }

    get bigThumbnailStyle() {
        if (defaultBigThumbnailBackground.toLowerCase() === this.bigThumbnailBackground.toLowerCase()) {
            return {}
        }

        return { backgroundColor: this.bigThumbnailBackground }
    }

    get active_spool(): ServerSpoolmanStateSpool | null {
        return this.$store.state.server.spoolman.active_spool ?? null
    }

    get filamentVendor() {
        return this.active_spool?.filament?.vendor?.name ?? 'Unknown'
    }

    get filamentName() {
        return this.active_spool?.filament.name ?? 'Unknown'
    }

    get filament() {
        return `${this.filamentVendor} - ${this.filamentName}`
    }

    get question() {
        if (this.active_spool)
            return this.$t('Dialogs.StartPrint.DoYouWantToStartFilenameFilament', {
                filename: this.file?.filename ?? 'unknown',
            })

        return this.$t('Dialogs.StartPrint.DoYouWantToStartFilename', { filename: this.file?.filename ?? 'unknown' })
    }

    get fileTimestamp() {
        return typeof this.file.modified.getTime === 'function' ? this.file.modified.getTime() : 0
    }

    get thumbnails() {
        return this.file.thumbnails ?? []
    }

    get bigThumbnail() {
        return this.thumbnails.find((thumbnail) => thumbnail.width >= thumbnailBigMin)
    }

    get currentPathWithoutSlash() {
        if (this.currentPath.startsWith('/')) return this.currentPath.substring(1)

        return this.currentPath
    }

    get bigThumbnailUrl() {
        if (this.bigThumbnail === undefined || !('relative_path' in this.bigThumbnail)) return null

        const baseArray = [this.apiUrl, 'server/files/gcodes']
        if (this.currentPathWithoutSlash) baseArray.push(this.currentPathWithoutSlash)
        baseArray.push(this.bigThumbnail.relative_path)
        const baseUrl = baseArray.join('/')

        return `${baseUrl}?timestamp=${this.fileTimestamp}`
    }

    get maxThumbnailWidth() {
        return this.bigThumbnail?.width ?? 400
    }

    startPrint(filename = '') {
        filename = (this.currentPath + '/' + filename).substring(1)
        this.closeDialog()
        this.$socket.emit('printer.print.start', { filename: filename }, { action: 'switchToDashboard' })
    }

    closeDialog() {
        this.$emit('closeDialog')
    }
}
</script>
