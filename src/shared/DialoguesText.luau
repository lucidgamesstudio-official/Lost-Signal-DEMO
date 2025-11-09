export type DialoguesDict = {
	title: string,
	lines: { string },
	speaker: string?,
	portrait: string?,
	style: number?,
}

return {
	fr = {
		Test = {
			lines = {
				"<b>Test</b>, autre test. <s>test strike</s>",
				"<font color='rgb(255, 0, 0)'>Player</font>, <i>test</i>, ponctuation. Time",
			},
			title = "TitleTest",
			speaker = "Me",
		},
	},
} :: { [string]: { [string]: DialoguesDict } }
